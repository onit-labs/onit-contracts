// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';

// Interface of the elliptic curve validator contract
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';
// Modified BaseAccount with nonce removed
import {BaseAccount, IEntryPoint, UserOperation} from '@interfaces/BaseAccount.sol';

import {Base64} from '@libraries/Base64.sol';

import 'forge-std/console.sol';

/**
 * @notice EIP4337 Managed Gnosis Safe Account Implementation
 * @author Forum (https://forumdaos.com)
 * @dev Uses infinitism style base 4337 interface, with gnosis safe account
 */

/**
 * TODO
 * - Handle variable ClientDataJson
 * - Consider security of added a generated address as owner on safe
 * - Integrate domain seperator in validation of signatures
 * - Use as a module until more finalised version is completed (for easier upgradability)
 * - Consider a function to upgrade owner
 * - Add restriction to check entryPoint is valid before setting
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

		// ! tmp testing
		// _owner = [
		// 	0x7088c8f47cbe4745dc5e9e44302dcf1a528766b48470dea245076b8e91ebe2c5,
		// 	0xe498cf1f4f1ed27c1db3e78d389673bb40f26fc7d2d9e3ae8ca247ff3ba6c570
		// ];

		// Owner must be passed to safe setup as an array of addresses
		address[] memory arrayOwner = new address[](1);
		// Take the last 20 bytes of the hashed public key as the address
		arrayOwner[0] = address(bytes20(keccak256(abi.encodePacked(anOwner[0], anOwner[1])) << 96));

		this.setup(
			arrayOwner,
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

	// ! testing only
	function _validateSignature(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		address
	) internal virtual override returns (uint256 sigTimeRange) {
		// Extract the passkey generated signature and authentacator data
		(uint256[2] memory s, bytes memory auth) = abi.decode(
			userOp.signature,
			(uint256[2], bytes)
		);

		console.log('-----------------');
		console.logBytes(auth);

		//bytes32(0x8381a509c43f9a7fe5a80145cace2799988f6e018fb24ffee62b87743fac38bb)
		bytes32 hashedClientData = sha256(
			abi.encodePacked(
				'{"type":"webauthn.get","challenge":"',
				Base64.encode(abi.encodePacked(userOpHash)),
				'","origin":"https://development.forumdaos.com"}'
			)
		);

		bytes32 message = sha256(
			abi.encodePacked(
				//userOp.signature[64:],
				hex'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000', //'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000',
				hashedClientData
			)
		);

		console.logBytes32(message);

		return
			_ellipticCurveValidator.validateSignature(
				//bytes32(0x331e04c82b160721ff30b8b6cd656a11331620b83e938ddca3eb29cf71bbc355),
				message,
				s,
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
