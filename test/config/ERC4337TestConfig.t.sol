// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// 4337 imports
import {EntryPoint} from '@erc4337/core/EntryPoint.sol';
import {BaseAccount, UserOperation} from '@erc4337/core/BaseAccount.sol';

// Forum 4337 contracts
import {ForumAccount} from '../../src/erc4337-account/ForumAccount.sol';
import {ForumAccountFactory} from '../../src/erc4337-account/ForumAccountFactory.sol';
import {ForumGroup} from '../../src/erc4337-group/ForumGroup.sol';
import {ForumGroupFactory} from '../../src/erc4337-group/ForumGroupFactory.sol';
import {MemberManager} from '@utils/MemberManager.sol';

// EllipticCurve validator used for p256 curves - compiled with v0.5.0
/// @dev To save changes to folder structure, this is built elsewhere and added to the ./out folder
///		 The file is the same as utils/EllipticCurve.sol, except uses 'pragma solidity 0.5.0;'
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';

import './SafeTestConfig.t.sol';
import './BasicTestConfig.t.sol';

contract ERC4337TestConfig is BasicTestConfig, SafeTestConfig {
	// 4337 Account Types

	// Entry point
	EntryPoint public entryPoint;

	// Singleton for Forum 4337 account implementation
	ForumAccount public forumAccountSingleton;

	// Singleton for Forum 4337 group account implementation
	ForumGroup public forumGroupSingleton;

	// Factory for individual 4337 accounts
	ForumAccountFactory public forumAccountFactory;

	// Factory for 4337 group accounts
	ForumGroupFactory public forumGroupFactory;

	// Elliptic curve validator
	IEllipticCurveValidator public ellipticCurveValidator;

	// Addresses for easy use in tests
	address internal entryPointAddress;

	string internal authentacatorData =
		'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000';

	// TODO set these to deploy based on env
	string internal clientDataStart = '{"type":"webauthn.get","challenge":"';
	string internal clientDataEndDevelopment = '","origin":"https://development.forumdaos.com"}';
	string internal clientDataEndProduction = '","origin":"https://production.forumdaos.com"}';

	constructor() {
		entryPoint = new EntryPoint();
		entryPointAddress = address(entryPoint);

		// Validator used for p256 curves - 0xBa81560Ae6Bd24D34BB24084993AfdaFad3cfeff can be used on mumbai forks
		ellipticCurveValidator = IEllipticCurveValidator(
			deployCode('EllipticCurve5.sol:EllipticCurve5')
		);

		forumAccountSingleton = new ForumAccount(ellipticCurveValidator);
		forumGroupSingleton = new ForumGroup(
			address(ellipticCurveValidator)
			//clientDataStart,
			//clientDataEndDevelopment
		);

		forumAccountFactory = new ForumAccountFactory(
			forumAccountSingleton,
			entryPoint,
			address(handler)
		);

		forumGroupFactory = new ForumGroupFactory(
			payable(address(forumGroupSingleton)),
			entryPointAddress,
			address(safeSingleton),
			address(handler)
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
				'executeAndRevert(address,uint256,bytes,uint8)',
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

	function failedOpError(
		uint256 opIndex,
		string memory reason
	) internal pure returns (bytes memory) {
		return abi.encodeWithSignature('FailedOp(uint256,string)', opIndex, reason);
	}
}
