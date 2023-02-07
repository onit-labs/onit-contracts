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

	error Unauthorized();

	// Public key for secp256r1 signer
	uint[2] internal _owner;

	// Entry point allowed to call methods directly on this contract
	IEntryPoint internal _entryPoint;

	// Contract used to validate the secp256r1 signature was signed by the owner
	IEllipticCurveValidator internal immutable _ellipticCurveValidator;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Constructor
	 * @dev This contract should be deployed using a proxy, the constructor should not be called
	 */
	constructor(IEllipticCurveValidator aValidator) GnosisSafe() {
		_owner = [1, 1];

		_ellipticCurveValidator = aValidator;
	}

	/**
	 * @notice Initialize the account
	 * @param initData Encoded: EntryPoint, Public key for secp256r1 signer, and fallback handler
	 * @dev This method should only be called once, and setup() will revert if needed
	 */
	function initialize(bytes calldata initData) public virtual {
		(IEntryPoint anEntryPoint, uint[2] memory anOwner, address gnosisFallbackLibrary) = abi
			.decode(initData, (IEntryPoint, uint[2], address));

		_entryPoint = anEntryPoint;

		_owner = anOwner;

		// Owner must be passed to safe setup as an array of addresses
		address[] memory arrayOwner = new address[](1);
		// Take the last 20 bytes of the hashed public key as the address
		arrayOwner[0] = address(bytes20(keccak256(abi.encodePacked(anOwner[0], anOwner[1])) << 96));

		this.setup(
			arrayOwner, // ! check if acceptable substitue for safe owner address
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

	function execute(
		address to,
		uint256 value,
		bytes memory data,
		Enum.Operation operation
	) external virtual {
		_requireFromEntryPoint();

		// Execute transaction without further confirmations.
		execute(to, value, data, operation, gasleft());
	}

	function setEntryPoint(IEntryPoint anEntryPoint) external virtual {
		_requireFromEntryPoint();

		_entryPoint = anEntryPoint;
	}

	function entryPoint() public view virtual override returns (IEntryPoint) {
		return _entryPoint;
	}

	function owner() public view virtual returns (uint[2] memory) {
		return _owner;
	}

	/// ----------------------------------------------------------------------------------------
	///							INTERNAL METHODS
	/// ----------------------------------------------------------------------------------------

	function _validateSignature(
		UserOperation calldata userOp,
		bytes32, //userOpHash,
		address
	) internal virtual override returns (uint256 sigTimeRange) {
		// ! create test function to create proper p256 sigs
		// ! TESTING WITH SET MESSAGE BELOW IN VALIDATE SIGNATURE
		//bytes32 hash = keccak256(abi.encodePacked(userOpHash, DOMAIN_SEPARATOR()));

		// json serialise userOpHash, a constant (webauthn.get or similar), and app domain

		return
			_ellipticCurveValidator.validateSignature(
				0xf2424746de28d3e593fb6af9c8dff6d24de434350366e60312aacfe79dae94a8,
				abi.decode(userOp.signature, (uint[2])),
				_owner
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
