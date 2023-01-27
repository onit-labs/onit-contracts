// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {Utils} from '@utils/Utils.sol';

import {BaseAccount, IEntryPoint, UserOperation} from '@eip4337/contracts/core/BaseAccount.sol';

//import {ForumSafeBaseModule, IForumSafeModuleTypes, Enum} from './ForumSafeBaseModule.sol';

/**
 * @notice 4337 Account implementation for ForumSafeModule
 * @author Forum
 * @dev A first pass at integrating 4337 with ForumSafeModule
 * - execute and manageAdmin function restricted to entrypoint only
 * - functions can only be called if validateSig passes
 * - extensions and call extension etc exist as before
 * - BaseAccount, ForumGovernace, and Safe Module logic are all in this contract
 *   should attempt to remove these and use a logic contract with delegate
 */

// ! consider seperating 4337 logic from contract
// Would allow validation and execution to be called on a logic contract,
// and this to be called from the forum module, or maybe safe
contract ForumSafe4337Module is BaseAccount {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event SimpleAccountInitialized(IEntryPoint indexed entryPoint, address indexed owner);

	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT STORAGE
	/// ----------------------------------------------------------------------------------------

	uint256 private _nonce;

	// 2d version used to allow out of order execution
	mapping(bytes32 => uint256) public usedNonces;

	IEntryPoint private immutable _entryPoint;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	// ! consider use of constructor if used in proxy
	constructor(IEntryPoint anEntryPoint) {
		_entryPoint = anEntryPoint;
	}

	/// ----------------------------------------------------------------------------------------
	///							ACCOUNT LOGIC
	/// ----------------------------------------------------------------------------------------

	// Incremented for each execute called here (not for extension based called for now)
	function nonce() public view virtual override returns (uint256) {
		return _nonce;
	}

	function entryPoint() public view virtual override returns (IEntryPoint) {
		return _entryPoint;
	}

	// ! very minimal validation, not secure at all
	function _validateSignature(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		address
	) internal virtual override returns (uint256 sigTimeRange) {
		// userOp.sigs should be a hash of the userOpHash, and the proposal hash for this contract
		// consider restrictions on what entrypoint can call?

		// Recover the signer
		address recoveredSigner = Utils.recoverSigner(userOpHash, userOp.signature, 0);

		return isOwner(recoveredSigner) ? 0 : SIG_VALIDATION_FAILED;
	}

	/// implement template method of BaseAccount
	function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {
		bytes32 userOpHash = _entryPoint.getUserOpHash(userOp);
		require(usedNonces[userOpHash] == 0, 'op already used');
		usedNonces[userOpHash] = 1;
		++_nonce;
	}

	function getRequiredSignatures() public view virtual returns (uint256) {
		// ! implement argent style check on allowed methods for single signer vs all sigs

		// check functions on this contract
		// check functions as the module
		// check batched or multicall calls

		return 0;
	}
}
