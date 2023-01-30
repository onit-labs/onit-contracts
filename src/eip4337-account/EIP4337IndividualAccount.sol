// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {BaseAccount, IEntryPoint, IAccount, UserOperation} from '@eip4337/contracts/core/BaseAccount.sol';

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {ERC20} from '@solbase/tokens/ERC20/ERC20.sol';

/**
 * @notice 4337 Gnosis Safe account implementation
 * @author Forum
 * @dev Uses infinitism style base account, with gnosis safe
 */

contract EIP4337IndividualAccount is BaseAccount, GnosisSafe {
	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT STORAGE
	/// ----------------------------------------------------------------------------------------

	error Unauthorized();

	// ! test nonce can be updated via safe instead of here
	// Transaction nonce on the account
	//uint256 internal _nonce;

	// Public key for secp256r1 signer
	uint[2] internal _owner;

	// Optional EOA owner which can be set used instead of the entrypoint based secp256r1 owner
	address internal _eoaOwner;

	// Entry point allowed to call methods directly on this contract
	IEntryPoint internal _entryPoint;

	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT LOGIC
	/// ----------------------------------------------------------------------------------------

	function entryPoint() public view virtual override returns (IEntryPoint) {
		return _entryPoint;
	}

	// Override conflicting nonce methods, taking the nonce from Safe
	function nonce() public view virtual override(BaseAccount, GnosisSafe) returns (uint256) {
		return GnosisSafe.nonce;
	}

	function owner() public view virtual returns (uint[2] memory) {
		return _owner;
	}

	function eoaOwner() public view virtual returns (address) {
		return _eoaOwner;
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

		// Instead of sending a separate transaction to approve tokens
		// for the paymaster for each transaction, it can be approved here
		if (paymaster != 0x0000000000000000000000000000000000000000)
			ERC20(approveToken).approve(paymaster, approveAmount);
	}

	/// ----------------------------------------------------------------------------------------
	///							INTERNAL METHODS
	/// ----------------------------------------------------------------------------------------

	function _requireFromEntryPointOrOwner() internal view {
		if (!(msg.sender == address(entryPoint()) || msg.sender == _eoaOwner))
			revert Unauthorized();
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
