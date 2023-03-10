// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// 4337 imports
import {EntryPoint} from '@erc4337/core/EntryPoint.sol';
import {BaseAccount, UserOperation} from '@erc4337/core/BaseAccount.sol';

// 4337 contracts
import {ERC4337Account} from '../../src/erc4337-account/ERC4337Account.sol';
import {ERC4337AccountFactory} from '../../src/erc4337-account/ERC4337AccountFactory.sol';
//import {ERC4337ValidationManager} from '../../src/erc4337-account/ERC4337ValidationManager.sol';
import {ForumGroupModule} from '../../src/erc4337-module/ForumGroupModule.sol';
import {ForumGroupFactory} from '../../src/erc4337-module/ForumGroupFactory.sol';

// EllipticCurve validator used for p256 curves - compiled with v0.5.0
/// @dev To save changes to folder structure, this is built elsewhere and added to the ./out folder
///		 The file is the same as utils/EllipticCurve.sol, except uses 'pragma solidity 0.5.0;'
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';

import './SafeTestConfig.t.sol';
import './ForumModuleTestConfig.t.sol';

contract ERC4337TestConfig is Test, SafeTestConfig, ForumModuleTestConfig {
	// 4337 Account Types

	// Entry point
	EntryPoint public entryPoint;

	// Singleton for Forum 4337 account implementation
	ERC4337Account public erc4337Singleton;

	// Singleton for Forum 4337 group account implementation
	ForumGroupModule public erc4337GroupSingleton;

	// Factory for individual 4337 accounts
	ERC4337AccountFactory public erc4337AccountFactory;

	// Factory for 4337 group accounts
	ForumGroupFactory public forumGroupFactory;

	// Elliptic curve validator
	IEllipticCurveValidator public ellipticCurveValidator;

	// Addresses for easy use in tests
	address internal entryPointAddress;

	string internal authentacatorData =
		'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000';

	constructor() {
		entryPoint = new EntryPoint();
		entryPointAddress = address(entryPoint);

		// Validator used for p256 curves - 0xBa81560Ae6Bd24D34BB24084993AfdaFad3cfeff can be used on mumbai forks
		ellipticCurveValidator = IEllipticCurveValidator(
			deployCode('EllipticCurve5.sol:EllipticCurve5')
		);

		erc4337Singleton = new ERC4337Account(ellipticCurveValidator);
		erc4337GroupSingleton = new ForumGroupModule(entryPointAddress, ellipticCurveValidator);

		erc4337AccountFactory = new ERC4337AccountFactory(
			erc4337Singleton,
			entryPoint,
			address(handler)
		);

		forumGroupFactory = new ForumGroupFactory(
			payable(address(erc4337GroupSingleton)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory),
			address(entryPoint)
		);
	}

	// -----------------------------------------------------------------------
	// 4337 Helper Functions
	// -----------------------------------------------------------------------

	UserOperation public userOpBase =
		UserOperation({
			sender: address(0),
			nonce: 0,
			initCode: new bytes(0),
			callData: new bytes(0),
			callGasLimit: 10000000,
			verificationGasLimit: 20000000,
			preVerificationGas: 20000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});

	function getNonce(BaseAccount account) internal view returns (uint256) {
		return account.nonce();
	}

	function buildUserOp(
		address sender,
		uint256 nonce,
		bytes memory initCode,
		bytes memory callData
	) public view returns (UserOperation memory userOp) {
		// Build on top of base op
		userOp = userOpBase;

		// Add sender and calldata to op
		userOp.sender = sender;
		userOp.nonce = nonce;
		userOp.initCode = initCode;
		userOp.callData = callData;
	}

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
