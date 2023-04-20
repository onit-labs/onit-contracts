// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {Safe, Enum} from '@safe/Safe.sol';
import {Secp256r1, PassKeyId} from '@aa-passkeys-wallet/Secp256r1.sol';

// Modified BaseAccount with nonce removed
import {BaseAccount, IEntryPoint, UserOperation} from '@interfaces/BaseAccount.sol';

import {Base64} from '@libraries/Base64.sol';
import {HexToLiteralBytes} from '@libraries/HexToLiteralBytes.sol';

import {Exec} from '@utils/Exec.sol';

/**
 * @notice ERC4337 Managed Gnosis Safe Account Implementation
 * @author Forum (https://forumdaos.com)
 * @dev Uses infinitism style base 4337 interface, with gnosis safe account
 * @custom:warning This contract has not been audited, and is likely to change.
 */

/**
 * TODO
 * - Integrate domain seperator in validation of signatures
 * - Use as a module until more finalised version is completed (for easier upgradability)
 * - Consider a function to upgrade owner
 * - Add restriction to check entryPoint is valid before setting
 * - Further access control on functions
 * - Add guardians and account recovery (beyond basic method of adding an EOA owner to Safe)
 */

contract ForumAccount is Safe, BaseAccount {
	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT STORAGE
	/// ----------------------------------------------------------------------------------------

	error Unauthorized();

	// Public key for secp256r1 signer
	uint256[2] internal _owner;

	// Entry point allowed to call methods directly on this contract
	IEntryPoint internal _entryPoint;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Constructor
	 * @dev This contract should be deployed using a proxy, the constructor should not be called
	 */
	constructor() {
		threshold = 1;
	}

	/**
	 * @notice Initialize the account
	 * @param  entryPoint_ The entrypoint that can call methods directly on this contract
	 * @param  owner_ The public key of the owner of this account
	 * @param  gnosisFallbackLibrary The fallback handler for the Gnosis Safe
	 * @dev This method should only be called once, and setup() will revert if already initialized
	 */
	function initialize(
		address entryPoint_,
		uint256[2] memory owner_,
		address gnosisFallbackLibrary
	) public virtual {
		_entryPoint = IEntryPoint(entryPoint_);

		_owner = owner_;

		// Owner must be passed to safe setup as an array of addresses
		address[] memory ownerPlaceholder = new address[](1);
		// Set dead address as owner, actions are controlled via this contract & entrypoint
		ownerPlaceholder[0] = address(0xdead);

		// Setup the Gnosis Safe - will revert if already initialized
		this.setup(
			ownerPlaceholder,
			1,
			address(0),
			new bytes(0),
			gnosisFallbackLibrary,
			address(0),
			0,
			payable(address(0))
		);
	}

	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT LOGIC
	/// ----------------------------------------------------------------------------------------

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
	) external payable {
		_requireFromEntryPoint();

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

	function setEntryPoint(IEntryPoint anEntryPoint) external virtual {
		_requireFromEntryPoint();

		_entryPoint = anEntryPoint;
	}

	function entryPoint() public view virtual override returns (IEntryPoint) {
		return _entryPoint;
	}

	function owner() public view virtual returns (uint256[2] memory) {
		return _owner;
	}

	/// ----------------------------------------------------------------------------------------
	///							INTERNAL METHODS
	/// ----------------------------------------------------------------------------------------

	/**
	 * validate the current nonce matches the UserOperation nonce.
	 * then it should update the account's state to prevent replay of this UserOperation.
	 * called only if initCode is empty (since "nonce" field is used as "salt" on account creation)
	 * @param userOp the op to validate.
	 */
	function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {
		require(Safe.nonce++ == userOp.nonce, 'account: invalid nonce');
	}

	/**
	 * @notice Validate the signature of the user operation
	 * @param userOp The user operation to validate
	 * @param userOpHash The hash of the user operation
	 * @return sigTimeRange The time range the signature is valid for
	 * @dev This is a first take at getting the signature validation working using passkeys
	 * - The signature may be validated using a domain seperator
	 * - More efficient validation of the hashing and conversion of authData is needed
	 */
	function _validateSignature(
		UserOperation calldata userOp,
		bytes32 userOpHash
	) internal virtual override returns (uint256 sigTimeRange) {
		// Extract the passkey generated signature and authentacator data
		(
			uint256[2] memory sig,
			string memory clientDataStart,
			string memory clientDataEnd,
			string memory authData
		) = abi.decode(userOp.signature, (uint256[2], string, string, string));

		// Hash the client data to produce the challenge signed by the passkey offchain
		bytes32 hashedClientData = sha256(
			abi.encodePacked(
				clientDataStart,
				Base64.encode(abi.encodePacked(userOpHash)),
				clientDataEnd
			)
		);

		return
			Secp256r1.Verify(
				PassKeyId(_owner[0], _owner[1], ''),
				sig[0],
				sig[1],
				uint256(
					sha256(abi.encodePacked(HexToLiteralBytes.fromHex(authData), hashedClientData))
				)
			)
				? 0
				: SIG_VALIDATION_FAILED;
	}
}
