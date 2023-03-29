// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// Forum 4337 contracts
import {ForumAccount} from '../src/erc4337-account/ForumAccount.sol';
import {ForumAccountFactory} from '../src/erc4337-account/ForumAccountFactory.sol';

// Infinitism 4337 contracts
import {EntryPoint} from '@erc4337/core/EntryPoint.sol';

import './config/ERC4337TestConfig.t.sol';
import {ERC4337SignatureStore} from './config/ERC4337SignatureStore.t.sol';

// ! need a way to generate test passkey sigs that match owner addresses
// ! until then some manual effor it required to run each test

contract ForumAccountTest is ERC4337TestConfig, ERC4337SignatureStore {
	uint256[2] internal publicKey;
	string internal constant SIGNER_1 = '1';

	// Variable used for test erc4337 account
	ForumAccount private deployed4337Account;
	address payable private deployed4337AccountAddress;

	// Some salts
	bytes32 private constant SALT_1 = keccak256('salt1');
	bytes32 private constant SALT_2 = keccak256('salt2');

	bytes internal basicTransferCalldata;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		publicKey = createPublicKey(SIGNER_1);

		// Check 4337 singelton is set in factory (base implementation for Forum 4337 accounts)
		assertEq(
			address(forumAccountFactory.forumAccountSingleton()),
			address(forumAccountSingleton),
			'forumAccountSingleton not set'
		);
		// Check 4337 entryPoint is set in factory
		assertEq(forumAccountFactory.entryPoint(), entryPointAddress, 'entryPoint not set');
		// Check 4337 gnosis fallback handler is set in factory
		assertEq(
			address(forumAccountFactory.gnosisFallbackLibrary()),
			address(handler),
			'handler not set'
		);

		// Deploy an account to be used in tests later
		deployed4337AccountAddress = forumAccountFactory.createForumAccount(
			signers[TestSigner.SignerA]
		);
		deployed4337Account = ForumAccount(deployed4337AccountAddress);

		// // Deal funds to account
		// deal(deployed4337AccountAddress, 1 ether);

		// Build a basic transaction to execute in some tests
		basicTransferCalldata = buildExecutionPayload(
			alice,
			uint256(0.5 ether),
			new bytes(0),
			Enum.Operation.Call
		);
	}

	/// -----------------------------------------------------------------------
	/// Deployment tests
	/// -----------------------------------------------------------------------

	function testFactoryDeploy() public {
		// Check that the account from setup is deployed and data is set on account, and safe
		assertEq(deployed4337Account.owner()[0], signers[TestSigner.SignerA][0], 'owner not set');
		assertEq(deployed4337Account.owner()[1], signers[TestSigner.SignerA][1], 'owner not set');
		assertEq(deployed4337Account.getThreshold(), 1, 'threshold not set');
		assertEq(deployed4337Account.getOwners()[0], address(0xdead), 'owner not set on safe');
		assertEq(
			address(deployed4337Account.entryPoint()),
			address(entryPoint),
			'entry point not set'
		);
	}

	function testFactoryDeployFromEntryPoint() public {
		//Encode the calldata for the factory to create an account
		bytes memory factoryCalldata = abi.encodeWithSignature(
			'createForumAccount(uint256[2])',
			publicKey
		);

		//Prepend the address of the factory
		bytes memory initCode = abi.encodePacked(address(forumAccountFactory), factoryCalldata);

		// Calculate address in advance to use as sender
		address preCalculatedAccountAddress = (forumAccountFactory).getAddress(
			accountSalt(publicKey)
		);
		// Deal funds to account
		deal(preCalculatedAccountAddress, 1 ether);
		// Cast to ForumAccount - used to make some test assertions easier
		ForumAccount testNew4337Account = ForumAccount(payable(preCalculatedAccountAddress));

		// Retrieve the userOp from signature store (in future generate this and sign it here)

		UserOperation[] memory userOps = signAndFormatUserOpIndividual(
			buildUserOp(preCalculatedAccountAddress, 0, initCode, basicTransferCalldata),
			SIGNER_1
		);

		// Handle userOp
		entryPoint.handleOps(userOps, payable(alice));

		// Check that the account is deployed and data is set on account, and safe
		assertEq(testNew4337Account.owner()[0], publicKey[0], 'owner not set');
		assertEq(testNew4337Account.owner()[1], publicKey[1], 'owner not set');
		assertEq(testNew4337Account.getThreshold(), 1, 'threshold not set');
		assertEq(testNew4337Account.getOwners()[0], address(0xdead), 'owner not set on safe');
		assertEq(
			address(testNew4337Account.entryPoint()),
			entryPointAddress,
			'entry point not set'
		);
	}

	function testCorrectAddressCrossChain() public {
		address tmpMumbai;
		address tmpFuji;

		// Fork Mumbai and create an account from a fcatory
		vm.createSelectFork(vm.envString('MUMBAI_RPC_URL'));

		forumAccountFactory = new ForumAccountFactory(
			forumAccountSingleton,
			entryPointAddress,
			address(handler)
		);

		// Deploy an account to be used in tests
		tmpMumbai = forumAccountFactory.createForumAccount(publicKey);

		// Fork Fuji and create an account from a fcatory
		vm.createSelectFork(vm.envString('FUJI_RPC_URL'));

		forumAccountFactory = new ForumAccountFactory(
			forumAccountSingleton,
			entryPointAddress,
			address(handler)
		);

		// Deploy an account to be used in tests
		tmpFuji = forumAccountFactory.createForumAccount(publicKey);

		assertEq(tmpMumbai, tmpFuji, 'address not the same');
	}

	/// -----------------------------------------------------------------------
	/// Execution tests
	/// -----------------------------------------------------------------------

	// ! consider a limit to prevent changing entrypoint to a contract that is not compatible with 4337
	function testUpdateEntryPoint() public {
		// Check old entry point is set
		assertEq(
			address(deployed4337Account.entryPoint()),
			entryPointAddress,
			'entry point not set'
		);

		// Build userop to set entrypoint to this contract as a test
		// UserOperation memory userOp = buildUserOp(
		// 	1, // use test account 1
		// 	deployed4337AccountAddress,
		// 	deployed4337Account.nonce(),
		// 	new bytes(0),
		// 	abi.encodeWithSignature('setEntryPoint(address)', address(this))
		// );
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOpUpdateEntryPoint;

		// Handle userOp
		entryPoint.handleOps(userOps, payable(this));

		// Check that the entry point has been updated
		assertEq(
			address(deployed4337Account.entryPoint()),
			address(this),
			'entry point not updated'
		);
	}

	function test4337AccountTransfer() public {
		// Build userop
		// UserOperation memory userOp = buildUserOp(
		// 	2, // use test account 2
		// 	deployed4337AccountAddress,
		// 	deployed4337Account.nonce(),
		// 	new bytes(0),
		// 	basicTransferCalldata
		// );
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOpTransfer;

		// Check nonce before tx
		assertEq(deployed4337Account.nonce(), 0, 'nonce not correct');

		// Handle userOp
		entryPoint.handleOps(userOps, payable(address(this)));

		uint256 gas = calculateGas(userOpTransfer);

		// Check updated balances
		assertEq(deployed4337AccountAddress.balance, 0.5 ether - gas, 'balance not updated');
		assertEq(alice.balance, 1.5 ether, 'balance not updated');

		// Check account nonce
		assertEq(deployed4337Account.nonce(), 1, 'nonce not updated');
	}

	function test4337AccountSafeAdmin() public {
		// Build payload to enable a module
		bytes memory enableModulePayload = abi.encodeWithSignature(
			'enableModule(address)',
			address(this)
		);

		bytes memory payload = buildExecutionPayload(
			deployed4337AccountAddress,
			0,
			enableModulePayload,
			Enum.Operation.Call
		);

		// Build userop
		// UserOperation memory userOp = buildUserOp(
		// 	1, // use test account 1
		// 	deployed4337AccountAddress,
		// 	deployed4337Account.nonce(),
		// 	new bytes(0),
		// 	payload
		// );
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOpAddModuleToSafe;

		// Check nonce before tx
		assertEq(deployed4337Account.nonce(), 0, 'nonce not correct');

		// Handle userOp
		entryPoint.handleOps(userOps, payable(address(this)));

		uint256 gas = calculateGas(userOpAddModuleToSafe);

		// Check updated balances
		assertEq(deployed4337AccountAddress.balance, 1 ether - gas, 'balance not updated');
		// Check account nonce
		assertEq(deployed4337Account.nonce(), 1, 'nonce not updated');
		// Check module is enabled
		assertTrue(deployed4337Account.isModuleEnabled(address(this)), 'module not enabled');
	}

	// ! Double check with new validation including the domain seperator
	function testCannotReplaySig() public {
		// Build first userop
		// UserOperation memory userOp = buildUserOp(
		// 	1, // use test account 1
		// 	deployed4337AccountAddress,
		// 	deployed4337Account.nonce(),
		// 	new bytes(0),
		// 	basicTransferCalldata
		// );
		UserOperation memory userOp = UserOperation({
			sender: deployed4337AccountAddress,
			nonce: 1,
			initCode: new bytes(0),
			callData: basicTransferCalldata,
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});
		console.logBytes32(entryPoint.getUserOpHash(userOp));

		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOp;

		// Check nonce before tx
		assertEq(deployed4337Account.nonce(), 0, 'nonce not correct');

		// Handle first userOp
		entryPoint.handleOps(userOps, payable(address(this)));
		assertEq(deployed4337Account.nonce(), 1, 'nonce not correct');

		// Build second userop, reusing signature
		userOps[0] = UserOperation({
			sender: deployed4337AccountAddress,
			nonce: deployed4337Account.nonce(),
			initCode: new bytes(0),
			callData: basicTransferCalldata,
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: abi.encodePacked(publicKey[0], publicKey[1])
		});

		vm.expectRevert();
		entryPoint.handleOps(userOps, payable(address(this)));
	}

	receive() external payable {
		// Allows this contract to receive ether
	}

	/// -----------------------------------------------------------------------
	/// Helper functions
	/// -----------------------------------------------------------------------

	function calculateOwnerAddress(uint[2] memory owner) internal pure returns (address) {
		return address(bytes20(keccak256(abi.encodePacked(owner[0], owner[1])) << 96));
	}

	function accountSalt(uint[2] memory owner) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(owner));
	}
}
