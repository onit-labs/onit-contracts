//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import {UserOperation} from '@eip4337/contracts/core/BaseAccount.sol';
import 'forge-std/console.sol';

contract ERC4337SignatureStore {
	/**
	 * @notice Mapping of test signers
	 * @dev
	 * - Signers (uint[2] public keys) are added to this mapping in the constructor
	 * - Signers are indexed by the TestSigner enum
	 */
	mapping(TestSigner => uint[2]) internal signers;

	// Setup arrays with userOps
	constructor() {
		for (uint i = 0; i < _signers.length; i++) {
			signers[TestSigner(i)] = _signers[i];
		}

		// console.logBytes(signerCTransaction3.callData);
	}

	// -----------------------------------------------------------------------
	// Signers
	// -----------------------------------------------------------------------

	/**
	 * @dev Signers enum used to index the signers mapping below
	 */
	enum TestSigner {
		SignerA,
		SignerB
	}

	/**
	 * @dev New signers can be added to this array, and a corresponding enum added to the TestSigner enum
	 */
	uint[2][] internal _signers = [
		[
			0xd3c6949ab309ff80296ffb17cd2a5298ec23ad7f1fda03ca70f12353987303de,
			0x42c164839f37f10fb2e6e5649c046a473a8d4db61d0602433fe32484d1c2d8d3
		],
		[
			0x7088c8f47cbe4745dc5e9e44302dcf1a528766b48470dea245076b8e91ebe2c5,
			0xe498cf1f4f1ed27c1db3e78d389673bb40f26fc7d2d9e3ae8ca247ff3ba6c570
		]
	];

	// -----------------------------------------------------------------------
	// Signatures
	// -----------------------------------------------------------------------

	/**
	 * todo: Script to generate passkeys and sigs, removing need to build pre signed test data
	 */

	/**
	 * @dev Signatures that can be used with SignerB account
	 */
	UserOperation internal signerBTransaction1 =
		UserOperation({
			sender: 0x9A13710ca108D389627b4Fc7dC0e3e699Bbc780C,
			nonce: 0,
			initCode: new bytes(0),
			callData: new bytes(0),
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: abi.encodePacked(
				[
					0x0fb0aa68dce6f1517cfb4cad4659a3ea403edc9f31994dd6bd2e1945df0f11bb,
					0x83479be56839e8c3e089613a02dd09f1a035751db0cb4fcf728bf94a231e0285
				],
				authenticatorDataBufferHex
			)
		});

	UserOperation internal userOpDeployFactoryFromEntryPoint =
		UserOperation({
			sender: 0x84C25C1252CA1f70C69109311739Ffcf786a6429,
			nonce: 0,
			initCode: hex'2a07706473244bc757e10f2a9e86fb532828afe3a01b76d7155be92b2f4d9840dffa6d5d9ec7c217158eaa53806e42820606ede6f9e17f257088c8f47cbe4745dc5e9e44302dcf1a528766b48470dea245076b8e91ebe2c5e498cf1f4f1ed27c1db3e78d389673bb40f26fc7d2d9e3ae8ca247ff3ba6c570',
			callData: new bytes(0),
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: abi.encode(
				[
					0x3c5ea098a6c6d4129e3d22e69f2772c010c2a42c7de599f4b10f12afabee7623,
					0x4eff56109849016469f288fc2648b234cd578a3a6ee2162fa42c11de6b0c5e37
				],
				'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000'
			)
		});

	UserOperation internal userOpUpdateEntryPoint =
		UserOperation({
			sender: 0xD6BbDE9174b1CdAa358d2Cf4D57D1a9F7178FBfF,
			nonce: 0,
			initCode: new bytes(0),
			callData: new bytes(0),
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});

	// Confirms admin operations work
	UserOperation internal userOpAddModuleToSafe =
		UserOperation({
			sender: 0xbF2f97c5315e14522e3F894f22474FFA0870A089,
			nonce: 0,
			initCode: new bytes(0),
			callData: hex'51945447000000000000000000000000bf2f97c5315e14522e3f894f22474ffa0870a0890000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024610b59250000000000000000000000007fa9385be102ac3eac297483dd6233d62b3e149600000000000000000000000000000000000000000000000000000000',
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});

	// test4337AccountTransfer
	UserOperation internal userOpTransfer =
		UserOperation({
			sender: 0xbF2f97c5315e14522e3F894f22474FFA0870A089,
			nonce: 0,
			initCode: new bytes(0),
			callData: hex'51945447000000000000000000000000328809bc894f92807417d2dad6b7c998c1afdac600000000000000000000000000000000000000000000000006f05b59d3b20000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});

	string internal authenticatorDataBufferHex =
		'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000';
}
