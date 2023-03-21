// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable avoid-low-level-calls */

import {Base64} from '@libraries/Base64.sol';
import {HexToLiteralBytes} from '@libraries/HexToLiteralBytes.sol';

import {Exec} from '@utils/Exec.sol';
import {MemberManager} from '@utils/MemberManager.sol';

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {IAccount} from '@erc4337/interfaces/IAccount.sol';
import {IEntryPoint, UserOperation} from '@erc4337/interfaces/IEntryPoint.sol';
import {Secp256r1, PassKeyId} from '../../lib/aa-passkeys-wallet/src/Secp256r1.sol'; // tidy import

/**
 * @notice Forum Group
 * @author Forum - Modified from infinitism https://github.com/eth-infinitism/account-abstraction/contracts/samples/gnosis/ERC4337Module.sol
 */
contract ForumGroup is IAccount, GnosisSafe, MemberManager {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS & ERRORS
	/// ----------------------------------------------------------------------------------------

	error ModuleAlreadySetUp();

	error NotFromEntrypoint();

	error InvalidInitialisation();

	error InvalidNonce();

	/// ----------------------------------------------------------------------------------------
	///							GROUP STORAGE
	/// ----------------------------------------------------------------------------------------

	// Should be made immutable - also consider removing variables and passing in signature
	string internal _clientDataStart;

	// Should be made immutable - also consider removing variables and passing in signature
	string internal _clientDataEnd;

	// Reference to latest entrypoint
	address internal _entryPoint;

	// Return value in case of signature failure, with no time-range.
	// Equivalent to _packValidationData(true,0,0);
	uint256 internal constant SIG_VALIDATION_FAILED = 1;

	// Used nonces; 1 = used (prevents replaying the same userOp, while allowing out of order execution)
	mapping(uint256 => uint256) public usedNonces;

	/// -----------------------------------------------------------------------
	/// 						SETUP
	/// -----------------------------------------------------------------------

	// Ensures the singleton can not be setup
	constructor() {
		voteThreshold = 1;
	}

	/**
	 * @notice Setup the module.
	 * @param _anEntryPoint The entrypoint to use on the safe
	 * @param fallbackHandler The fallback handler to use on the safe
	 * @param _voteThreshold Vote threshold to pass (basis points of 10,000 ie. 6,000 = 60%)
	 * @param _members The public key pairs of the signing members of the group
	 */
	function setUp(
		address _anEntryPoint,
		address fallbackHandler,
		uint256 _voteThreshold,
		uint256[2][] memory _members,
		string memory clientDataStart,
		string memory clientDataEnd
	) external {
		// Can only be set up once
		if (voteThreshold != 0) revert ModuleAlreadySetUp();

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

		if (
			_anEntryPoint == address(0) ||
			_voteThreshold < 1 ||
			_voteThreshold > _members.length ||
			_members.length < 1
		) revert InvalidInitialisation();

		_entryPoint = _anEntryPoint;

		_clientDataStart = clientDataStart;

		_clientDataEnd = clientDataEnd;

		// Set up the members
		setupMembers(_members, _voteThreshold);
	}

	/// -----------------------------------------------------------------------
	/// 						EXECUTION
	/// -----------------------------------------------------------------------

	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 validationData) {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// Extract the passkey generated signature and authentacator data
		// Signer index is the index of the signer in the members array, used to retrieve the public key
		(uint256[] memory signerIndex, uint256[2][] memory sig, string memory authData) = abi
			.decode(userOp.signature, (uint256[], uint256[2][], string));

		// Hash the client data to produce the challenge signed by the passkey offchain
		bytes32 hashedClientData = sha256(
			abi.encodePacked(
				_clientDataStart,
				Base64.encode(abi.encodePacked(userOpHash)),
				_clientDataEnd
			)
		);

		bytes32 fullMessage = sha256(
			abi.encodePacked(HexToLiteralBytes.fromHex(authData), hashedClientData)
		);

		uint256 count;

		for (uint i; i < signerIndex.length; ) {
			// Check if the signature is valid and increment count if so
			if (
				Secp256r1.Verify(
					PassKeyId(members[signerIndex[i]].x, members[signerIndex[i]].y, ''),
					sig[i][0],
					sig[i][1],
					uint(fullMessage)
				)
			) ++count;

			++i;
		}

		if (count < voteThreshold) {
			validationData = SIG_VALIDATION_FAILED;
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

	function setEntryPoint(address anEntryPoint) external {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// ! consider checks that entrypoint is valid here !
		// ! potential to brick account !
		_entryPoint = anEntryPoint;
	}

	/// -----------------------------------------------------------------------
	/// 						VIEW FUNCTIONS
	/// -----------------------------------------------------------------------

	function entryPoint() public view virtual returns (address) {
		return _entryPoint;
	}
}
