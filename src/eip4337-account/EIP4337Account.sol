// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {ERC20} from '@solbase/tokens/ERC20/ERC20.sol';

// Modified interface with nonce removed
import '@interfaces/BaseAccount.sol';

/**
 * @notice EIP4337 Managed Gnosis Safe Account Implementation
 * @author Forum (https://forumdaos.com)
 * @dev Uses infinitism style base 4337 interface, with gnosis safe account
 */

contract EIP4337Account is GnosisSafe, BaseAccount {
	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT STORAGE
	/// ----------------------------------------------------------------------------------------

	error Initialised();

	error Unauthorized();

	// Public key for secp256r1 signer
	uint[2] internal _owner;

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
		_owner = [1, 1];
	}

	/**
	 * @notice Initialize the account
	 * @param anOwner Public key for secp256r1 signer
	 * @dev This method should only be called
	 */
	function initialize(IEntryPoint anEntryPoint, uint[2] calldata anOwner) public virtual {
		if (_owner[0] != 0 || _owner[1] != 0) revert Initialised();

		_owner = anOwner;
		_entryPoint = anEntryPoint;
	}

	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT LOGIC
	/// ----------------------------------------------------------------------------------------

	function entryPoint() public view virtual override returns (IEntryPoint) {
		return _entryPoint;
	}

	function owner() public view virtual returns (uint[2] memory) {
		return _owner;
	}

	function execute(
		address to,
		uint256 value,
		bytes memory data,
		Enum.Operation operation,
		address paymaster,
		address approveToken,
		uint256 approveAmount
	) external virtual {
		_requireFromEntryPointOrOwner();

		// Execute transaction without further confirmations.
		execute(to, value, data, operation, gasleft());
	}

	function setEntryPoint(IEntryPoint anEntryPoint) external virtual {
		_requireFromEntryPointOrOwner();

		_entryPoint = anEntryPoint;
	}

	/// ----------------------------------------------------------------------------------------
	///							INTERNAL METHODS
	/// ----------------------------------------------------------------------------------------

	function _requireFromEntryPointOrOwner() internal view {
		if (msg.sender != address(entryPoint())) revert Unauthorized();
	}

	// ! very minimal validation, not secure at all
	function _validateSignature(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		address
	) internal virtual override returns (uint256 sigTimeRange) {
		// userOp.sigs should be a hash of the userOpHash, and the proposal hash for this contract
		// consider restrictions on what entrypoint can call?
		//return isOwner(recoveredSigner) ? 0 : SIG_VALIDATION_FAILED;
	}

	/**
	 * validate the current nonce matches the UserOperation nonce.
	 * then it should update the account's state to prevent replay of this UserOperation.
	 * called only if initCode is empty (since "nonce" field is used as "salt" on account creation)
	 * @param userOp the op to validate.
	 */
	function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {
		require(GnosisSafe.nonce++ == userOp.nonce, 'account: invalid nonce');
	}
}
