// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

import {IEntryPoint} from '@account-abstraction/interfaces/IEntryPoint.sol';
import {IAccount} from '@account-abstraction/interfaces/IAccount.sol';
import {UserOperation} from '@account-abstraction/interfaces/UserOperation.sol';

import {BaseAccount} from '@account-abstraction/core/BaseAccount.sol';

/**
 * @notice 4337 Account implementation for ForumSafeModule
 * @author Forum
 * @dev A first pass at integrating 4337 with ForumSafeModule
 * - proposal function remains but will be removed in future
 * - propose and process are restricted to entrypoint only
 * - functions can only be called if validateSig passes
 * - extensions and call extension etc exist as before
 * - BaseAccount, ForumGovernace, and Safe Module logic are all in this contract
 *   should attempt to remove these and use a logic contract with delegate
 */

// ! consider seperating 4337 logic from contract
// Would allow validation and execution to be called on a logic contract,
// and this to be called from the forum module, or maybe safe
contract ForumSafeAccount is BaseAccount {
	using ECDSA for bytes32;

	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event SimpleAccountInitialized(IEntryPoint indexed entryPoint, address indexed owner);

	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT STORAGE
	/// ----------------------------------------------------------------------------------------

	//explicit sizes of nonce, to fit a single storage cell with "owner"
	uint96 private _nonce;
	// ! consider owner here -> module? safe? member?
	//address public owner;

	IEntryPoint private immutable _entryPoint;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	constructor(IEntryPoint anEntryPoint) {
		_entryPoint = anEntryPoint;
	}

	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT LOGIC
	/// ----------------------------------------------------------------------------------------

	// ! consider nonce in relation to general module / safe transactions
	// do we increment it for each entry point tx only? or every tx including extensions?
	function nonce() public view virtual override returns (uint256) {
		return _nonce;
	}

	function entryPoint() public view virtual override returns (IEntryPoint) {
		return _entryPoint;
	}

	/// implement template method of BaseAccount
	function _validateSignature(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		address
	) internal virtual override returns (uint256 sigTimeRange) {
		// bytes32 hash = userOpHash.toEthSignedMessageHash();
		// if (owner != hash.recover(userOp.signature))
		//     return SIG_VALIDATION_FAILED;
		// return 0;
		// Implement validation logic here
	}

	/// implement template method of BaseAccount
	function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {
		require(_nonce++ == userOp.nonce, 'account: invalid nonce');
	}

	function getRequiredSignatures() public view virtual returns (uint256) {
		// ! implement
		return 0;
	}
}
