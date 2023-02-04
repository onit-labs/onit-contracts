// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';

// Interface of the elliptic curve validator contract
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';
// Modified BaseAccount with nonce removed
import {BaseAccount, IEntryPoint, UserOperation} from '@interfaces/BaseAccount.sol';

import 'forge-std/console.sol';

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

	// Contract used to validate the signature was signed by the owner
	IEllipticCurveValidator internal immutable _ellipticCurveValidator;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Constructor
	 * @dev This contract should be deployed using a proxy, the constructor should not be called
	 *		Pre set the entryPoint and ellipticCurveValidator to save gas on deployments
	 */
	constructor(IEllipticCurveValidator aValidator) GnosisSafe() {
		_owner = [1, 1];

		_ellipticCurveValidator = aValidator;
	}

	/**
	 * @notice Initialize the account
	 * @param anOwner Public key for secp256r1 signer
	 * @dev This method should only be called
	 */
	function initialize(IEntryPoint anEntryPoint, uint[2] calldata anOwner) public virtual {
		if (_owner[0] != 0 || _owner[1] != 0) revert Initialised();

		_entryPoint = anEntryPoint;

		_owner = anOwner;
	}

	/// ----------------------------------------------------------------------------------------
	///							EIP-712 STYLE LOGIC
	/// ----------------------------------------------------------------------------------------

	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
		return
			keccak256(
				abi.encode(
					// keccak256('EIP712Domain(string version,uint256 chainId,address verifyingContract)')
					0x8990460956f759a70e263603272cebd0a6ac6dc523b7334ddce05daee4d94d83,
					//keccak256('0.1.0'),
					0x20c949dc33efc49625bfe13e8da716e725117224147d54a7f00c902f6bf68693,
					block.chainid,
					address(this)
				)
			);
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
		// ! create test function to create proper p256 sigs
		// ! TESTING WITH SET MESSAGE BELOW IN VALIDATE SIGNATURE
		bytes32 hash = keccak256(abi.encodePacked(userOpHash, DOMAIN_SEPARATOR()));

		return
			_ellipticCurveValidator.validateSignature(
				0xf2424746de28d3e593fb6af9c8dff6d24de434350366e60312aacfe79dae94a8,
				_owner,
				abi.decode(userOp.signature, (uint[2]))
			)
				? 0
				: SIG_VALIDATION_FAILED;
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
