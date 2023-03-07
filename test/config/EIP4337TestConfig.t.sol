// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// 4337 imports
import {EntryPoint} from '@eip4337/core/EntryPoint.sol';
import {BaseAccount, UserOperation} from '@eip4337/core/BaseAccount.sol';

// 4337 contracts
import {EIP4337Account} from '../../src/eip4337-account/EIP4337Account.sol';
import {EIP4337AccountFactory} from '../../src/eip4337-account/EIP4337AccountFactory.sol';
//import {EIP4337ValidationManager} from '../../src/eip4337-account/EIP4337ValidationManager.sol';
import {ForumGroupModule} from '../../src/eip4337-module/ForumGroupModule.sol';
import {ForumGroupFactory} from '../../src/eip4337-module/ForumGroupFactory.sol';

// EllipticCurve validator used for p256 curves - compiled with v0.5.0
/// @dev To save changes to folder structure, this is built elsewhere and added to the ./out folder
///		 The file is the same as utils/EllipticCurve.sol, except uses 'pragma solidity 0.5.0;'
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';

import './SafeTestConfig.t.sol';
import './ForumModuleTestConfig.t.sol';

contract EIP4337TestConfig is Test, SafeTestConfig, ForumModuleTestConfig {
	// 4337 Account Types

	// Entry point
	EntryPoint public entryPoint;

	// Singleton for Forum 4337 account implementation
	EIP4337Account public eip4337Singleton;

	// Singleton for Forum 4337 group account implementation
	ForumGroupModule public eip4337GroupSingleton;

	// Validation manager used to check signatures for a 4337 group
	//EIP4337ValidationManager public eip4337ValidationManager;
	address internal eip4337ValidationManager = 0xBa81560Ae6Bd24D34BB24084993AfdaFad3cfeff; //on mumbai

	// Factory for individual 4337 accounts
	EIP4337AccountFactory public eip4337AccountFactory;

	// Factory for 4337 group accounts
	ForumGroupFactory public forumGroupFactory;

	// Elliptic curve validator
	IEllipticCurveValidator public ellipticCurveValidator;

	// Addresses for easy use in tests
	address internal entryPointAddress;
	//address internal eip4337ValidationManagerAddress;

	// Stuct for sigs to be decoded by p256 solidity library
	struct TestSig {
		uint[2] sig;
		uint[2] signer;
		bytes32 message;
	}

	constructor() {
		entryPoint = new EntryPoint();
		entryPointAddress = address(entryPoint);

		//eip4337ValidationManager = new EIP4337ValidationManager();
		//eip4337ValidationManagerAddress = address(eip4337ValidationManager);

		// Validator used for p256 curves
		ellipticCurveValidator = IEllipticCurveValidator(
			deployCode('EllipticCurve5.sol:EllipticCurve5')
		);

		eip4337Singleton = new EIP4337Account(ellipticCurveValidator);
		eip4337GroupSingleton = new ForumGroupModule(entryPointAddress);

		eip4337AccountFactory = new EIP4337AccountFactory(
			eip4337Singleton,
			entryPoint,
			address(handler)
		);

		forumGroupFactory = new ForumGroupFactory(
			payable(address(eip4337GroupSingleton)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory),
			address(entryPoint),
			eip4337ValidationManager,
			address(fundraiseExtension),
			address(withdrawalExtension),
			address(0)
		);
	}

	// -----------------------------------------------------------------------
	// 4337 Helper Functions
	// -----------------------------------------------------------------------

	function getNonce(BaseAccount account) internal view returns (uint256) {
		return account.nonce();
	}

	// ! This should be replaced when generation of signatures is done programatically
	// function buildUserOp(
	// 	uint8 testSignatureData,
	// 	address sender,
	// 	uint256 nonce,
	// 	bytes memory initCode,
	// 	bytes memory callData
	// ) public view returns (UserOperation memory userOp) {
	// 	// Build on top of base op
	// 	userOp = userOpBase;

	// 	// Add sender and calldata to op
	// 	userOp.sender = sender;
	// 	userOp.nonce = nonce;
	// 	userOp.initCode = initCode;
	// 	userOp.callData = callData;

	// 	// Improve this now we have multiple
	// 	TestSig memory testSig = testSignatureData == 1 ? testSig1 : testSignatureData == 2
	// 		? testSig2
	// 		: testSig3;

	// 	userOp.signature = abi.encode(
	// 		[testSig.sig[0], testSig.sig[1]],
	// 		authenticatorDataBufferHex2
	// 	);
	// }

	// Build payload which the entryPoint will call on the sender 4337 account
	function buildExecutionPayload(
		address to,
		uint256 value,
		bytes memory data,
		Enum.Operation operation
	) internal pure returns (bytes memory) {
		return
			abi.encodeWithSignature(
				'execute(address,uint256,bytes,uint8)',
				to,
				value,
				data,
				operation
			);
	}

	// Calculate gas used by sender of userOp
	// ! currently only works when paymaster set to 0 - hence 'address(0) != address(0)'
	function calculateGas(UserOperation memory userOp) internal pure returns (uint256) {
		uint256 mul = address(0) != address(0) ? 3 : 1;
		uint256 requiredGas = userOp.callGasLimit +
			userOp.verificationGasLimit *
			mul +
			userOp.preVerificationGas;

		return requiredGas * userOp.maxFeePerGas;
	}
}
