// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {EntryPoint} from '@eip4337/contracts/core/EntryPoint.sol';
import {BaseAccount, UserOperation} from '@eip4337/contracts/core/BaseAccount.sol';
import {EIP4337Manager} from '../../../src/eip4337-manager/EIP4337Manager.sol';

import {Module, Enum} from '@gnosis.pm/zodiac/contracts/core/Module.sol';

// Gnosis Safe imports
import {GnosisSafe} from '@gnosis/GnosisSafe.sol';
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';
import {MultiSend} from '@gnosis/libraries/MultiSend.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';
import {SignMessageLib} from '@gnosis/examples/libraries/SignMessage.sol';

// Forum imports
import {ForumSafe4337Factory} from '../../../src/eip4337-module/ForumSafe4337Factory.sol';
import {ForumSafe4337Module} from '../../../src/eip4337-module/ForumSafe4337Module.sol';

// Forum extension imports
import {ForumFundraiseExtension} from '../../../src/gnosis-forum/extensions/fundraise/ForumFundraiseExtension.sol';
import {ForumWithdrawalExtension} from '../../../src/gnosis-forum/extensions/withdrawal/ForumWithdrawalExtension.sol';

// Forum interfaces
import {IForumSafeModuleTypes} from '../../../src/interfaces/IForumSafe4337ModuleTypes.sol';

import './BasicTestConfig.t.sol';

import 'forge-std/Test.sol';

// !! a lot of repetition here, need to create factory with new 4337 contracts in a cleaner way
contract Helper4337 is Test, BasicTestConfig {
	EntryPoint public entryPoint;
	EIP4337Manager public eip4337Manager;

	address public entryPointAddress;

	// Safe contract types
	GnosisSafe internal safeSingleton;
	MultiSend internal multisend;
	CompatibilityFallbackHandler internal handler;
	GnosisSafeProxyFactory internal safeProxyFactory;
	SignMessageLib internal signMessageLib;

	// Forum contract types
	ForumSafe4337Module internal forumSafe4337ModuleSingleton;
	ForumSafe4337Factory internal forumSafe4337Factory;

	// Forum extensions
	ForumFundraiseExtension internal fundraiseExtension;
	ForumWithdrawalExtension internal withdrawalExtension;

	// Declare arrys used to setup forum groups
	address[] internal voters = new address[](1);
	address[] internal initialExtensions = new address[](1);

	address internal zeroAddress = address(0);
	address internal oneAddress = address(1);

	address internal safeAddress;
	address internal moduleAddress;
	address internal fundraiseAddress;

	constructor() {
		entryPoint = new EntryPoint();
		entryPointAddress = address(entryPoint);

		safeSingleton = new GnosisSafe();
		multisend = new MultiSend();
		handler = new CompatibilityFallbackHandler();
		safeProxyFactory = new GnosisSafeProxyFactory();
		signMessageLib = new SignMessageLib();

		eip4337Manager = new EIP4337Manager();

		//forumSafe4337ModuleSingleton = new ForumSafe4337Module(entryPoint);
		forumSafe4337Factory = new ForumSafe4337Factory(
			alice,
			payable(address(forumSafe4337ModuleSingleton)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory),
			entryPointAddress,
			address(eip4337Manager),
			address(fundraiseExtension),
			address(withdrawalExtension),
			address(0) // pfpSetter - not used in tests
		);

		voters[0] = alice;
	}

	// -----------------------------------------------------------------------
	// User Op Templates
	// -----------------------------------------------------------------------

	// Base for a  User Operation
	UserOperation public userOpBase =
		UserOperation({
			sender: address(0),
			nonce: 0,
			initCode: new bytes(0),
			callData: new bytes(0),
			callGasLimit: 2100000,
			verificationGasLimit: 1000000,
			preVerificationGas: 2100000,
			maxFeePerGas: 0,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});

	// -----------------------------------------------------------------------
	// 4337 Helper Functions
	// -----------------------------------------------------------------------

	function getNonce(BaseAccount account) internal view returns (uint256) {
		return account.nonce();
	}

	function buildUserOp(
		ForumSafe4337Module forumSafe4337Module,
		bytes memory callData,
		uint256 signerPk
	) public returns (UserOperation memory userOp) {
		// Build on top of base op
		userOp = userOpBase;

		// Add sender and calldata to op
		userOp.sender = address(forumSafe4337Module);
		userOp.callData = callData;

		// Get sig and add to op (sign the hast of the userop)
		bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, userOpHash);
		userOp.signature = abi.encodePacked(r, s, v);
	}

	// -----------------------------------------------------------------------
	// Updated from safe test config
	// -----------------------------------------------------------------------

	function buildDynamicArraysForProposal(
		address[1] memory _accounts,
		uint256[1] memory _amounts,
		bytes[1] memory _payloads
	)
		internal
		pure
		returns (address[] memory accounts, uint256[] memory amounts, bytes[] memory payloads)
	{
		accounts = new address[](_accounts.length);
		amounts = new uint256[](_amounts.length);
		payloads = new bytes[](_payloads.length);

		for (uint256 i = 0; i < _accounts.length; i++) {
			accounts[i] = _accounts[i];
			amounts[i] = _amounts[i];
			payloads[i] = _payloads[i];
		}
	}

	// For now this works for simple, 1 account, 1 amount, 1 payload peoposals
	function buildExecutionPayload(
		Enum.Operation operationType,
		address[1] memory accounts,
		uint256[1] memory amounts,
		bytes[1] memory payloads
	) internal returns (bytes memory) {
		(
			address[] memory _accounts,
			uint256[] memory _amounts,
			bytes[] memory _payloads
		) = buildDynamicArraysForProposal(accounts, amounts, payloads);

		return
			abi.encodeWithSignature(
				'execute(bytes)',
				abi.encode(operationType, _accounts, _amounts, _payloads)
			);
		// abi.encode(operationType, _accounts, _amounts, _payloads);
	}

	// For now this works for simple, 1 account, 1 amount, 1 payload peoposals
	function buildManageAdminPayload(
		IForumSafeModuleTypes.ProposalType proposalType,
		address[1] memory accounts,
		uint256[1] memory amounts,
		bytes[1] memory payloads
	) internal returns (bytes memory) {
		(
			address[] memory _accounts,
			uint256[] memory _amounts,
			bytes[] memory _payloads
		) = buildDynamicArraysForProposal(accounts, amounts, payloads);

		return
			abi.encodeWithSignature(
				'manageAdmin(uint8,address[],uint256[],bytes[])',
				proposalType,
				_accounts,
				_amounts,
				_payloads
			);
		//return abi.encode(proposalType, _accounts, _amounts, _payloads);
	}
}
