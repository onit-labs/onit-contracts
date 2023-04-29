// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/* solhint-disable avoid-low-level-calls */

import {Base64} from '@libraries/Base64.sol';
import {HexToLiteralBytes} from '@libraries/HexToLiteralBytes.sol';

import {Exec} from '@utils/Exec.sol';
import {MemberManager} from '@utils/MemberManager.sol';

import {Safe, Enum} from '@safe/Safe.sol';
import {IAccount} from '@erc4337/interfaces/IAccount.sol';
import {UserOperation} from '@erc4337/interfaces/IEntryPoint.sol';
import {Secp256r1, PassKeyId} from '@aa-passkeys-wallet/Secp256r1.sol';

/**
 * @title Forum Group
 * @notice A group 4337 wallet based on eth-infinitism IAccount, built on safe
 * @author Forum (https://github.com/forumdaos/contracts)
 * @custom:warning This contract has not been audited, and is likely to change.
 */

/**
 * TODO
 * - Add moduleAdmin function to handle adding members, changing threshold etc
 * - Add extension function to call extensions without needing full validation
 * - Add governance 1155
 * - Add check to prevent setting wrong entrypoint
 */

contract ForumGroup is IAccount, Safe, MemberManager {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS & ERRORS
	/// ----------------------------------------------------------------------------------------

	error InvalidNonce();

	error NotFromEntrypoint();

	error InvalidInitialisation();

	/// ----------------------------------------------------------------------------------------
	///							GROUP STORAGE
	/// ----------------------------------------------------------------------------------------

	// Reference to latest entrypoint
	address internal _entryPoint;

	// Return value in case of signature failure, with no time-range.
	// Equivalent to _packValidationData(true,0,0);
	uint256 internal constant _SIG_VALIDATION_FAILED = 1;

	string public constant GROUP_VERSION = 'v0.0.1';

	// Used nonces; 1 = used (prevents replaying the same userOp, while allowing out of order execution)
	mapping(uint256 => uint256) public usedNonces;

	/// -----------------------------------------------------------------------
	/// 						SETUP
	/// -----------------------------------------------------------------------

	constructor(address singletonAccount_) MemberManager(singletonAccount_) {
		// Set the threshold on the safe, prevents calling initalise so good for singleton
		threshold = 1;
	}

	/**
	 * @notice Setup the group account.
	 * @param entryPoint_ The entrypoint to use on the safe
	 * @param fallbackHandler The fallback handler to use on the safe
	 * @param voteThreshold_ Vote threshold to pass (counted in members)
	 * @param members_ The public key pairs of the signing members of the group
	 * @dev This function is only callable once, and is used to set up the group (setup will revert if called again)
	 */
	function initalize(
		address entryPoint_,
		address fallbackHandler,
		uint256 voteThreshold_,
		uint256[2][] memory members_
	) external {
		// Create a placeholder owner
		address[] memory ownerPlaceholder = new address[](1);
		ownerPlaceholder[0] = address(0xdead);

		// Setup the safe with placeholder owner and threshold 1
		this.setup(
			ownerPlaceholder,
			1,
			address(0),
			new bytes(0),
			fallbackHandler,
			address(0),
			0,
			payable(address(0))
		);

		uint256 len = members_.length;

		if (entryPoint_ == address(0) || voteThreshold_ < 1 || voteThreshold_ > len || len < 1)
			revert InvalidInitialisation();

		_entryPoint = entryPoint_;

		_voteThreshold = voteThreshold_;

		// Set up the members
		for (uint256 i; i < len; ) {
			// Create a hash used to identify the member
			address membersAddress = publicKeyAddress(Member(members_[i][0], members_[i][1]));

			// Add key pair to the members mapping
			_members[membersAddress] = Member(members_[i][0], members_[i][1]);
			// Add hash to the members array
			_membersAddressArray.push(membersAddress);

			unchecked {
				++i;
			}
		}
	}

	/// -----------------------------------------------------------------------
	/// 						VALIDATION
	/// -----------------------------------------------------------------------

	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 validationData) {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// Extract the passkey generated signature and authentacator data
		// Signer index is the index of the signer in the members array, used to retrieve the public key
		(
			uint256[] memory signerIndex,
			uint256[2][] memory sig,
			string memory clientDataStart,
			string memory clientDataEnd,
			string[] memory authData
		) = abi.decode(userOp.signature, (uint256[], uint256[2][], string, string, string[]));

		// Hash the client data to produce the challenge signed by the passkey offchain
		bytes32 hashedClientData = sha256(
			abi.encodePacked(
				clientDataStart,
				Base64.encode(abi.encodePacked(userOpHash)),
				clientDataEnd
			)
		);

		bytes32 fullMessage;

		uint256 count;

		for (uint i; i < signerIndex.length; ) {
			fullMessage = sha256(
				abi.encodePacked(HexToLiteralBytes.fromHex(authData[i]), hashedClientData)
			);

			// Check if the signature is valid and increment count if so
			if (
				Secp256r1.Verify(
					PassKeyId(
						_members[_membersAddressArray[signerIndex[i]]].x,
						_members[_membersAddressArray[signerIndex[i]]].y,
						''
					),
					sig[i][0],
					sig[i][1],
					uint(fullMessage)
				)
			) ++count;

			++i;
		}

		if (count < _voteThreshold) {
			validationData = _SIG_VALIDATION_FAILED;
		}

		// usedNonces mapping keeps the option to execute nonces out of order
		// We increment nonce so we have a way to keep track of the next available nonce
		if (userOp.initCode.length == 0) {
			if (usedNonces[userOp.nonce] == 1) revert InvalidNonce();
			++usedNonces[userOp.nonce];
			++nonce;
		}

		if (missingAccountFunds > 0) {
			//Note: MAY pay more than the minimum, to deposit for future transactions
			(bool success, ) = payable(msg.sender).call{value: missingAccountFunds}('');
			(success);
			//ignore failure (its EntryPoint's job to verify, not account.)
		}
	}

	/// -----------------------------------------------------------------------
	/// 						EXECUTION
	/// -----------------------------------------------------------------------

	/**
	 * Execute a call but also revert if the execution fails.
	 * The default behavior of the Safe is to not revert if the call fails,
	 * which is challenging for integrating with ERC4337 because then the
	 * EntryPoint wouldn't know to emit the UserOperationRevertReason event,
	 * which the frontend/client uses to capture the reason for the failure.
	 */
	function executeAndRevert(
		address to,
		uint256 value,
		bytes memory data,
		Enum.Operation operation
	) external {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		bool success = execute(to, value, data, operation, type(uint256).max);

		bytes memory returnData = Exec.getReturnData(type(uint256).max);
		// Revert with the actual reason string
		// Adopted from: https://github.com/Uniswap/v3-periphery/blob/464a8a49611272f7349c970e0fadb7ec1d3c1086/contracts/base/Multicall.sol#L16-L23
		if (!success) {
			if (returnData.length < 68) revert();
			assembly {
				returnData := add(returnData, 0x04)
			}
			revert(abi.decode(returnData, (string)));
		}
	}

	/// -----------------------------------------------------------------------
	/// 						GROUP MANAGEMENT
	/// -----------------------------------------------------------------------

	function setEntryPoint(address entryPoint_) external {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// ! consider checks that entrypoint is valid here !
		// ! potential to brick account !
		_entryPoint = entryPoint_;
	}

	/// -----------------------------------------------------------------------
	/// 						VIEW FUNCTIONS
	/// -----------------------------------------------------------------------

	function entryPoint() public view virtual returns (address) {
		return _entryPoint;
	}
}
