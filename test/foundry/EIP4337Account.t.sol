// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// Forum 4337 contracts
import {EIP4337Account} from '../../src/eip4337-account/EIP4337Account.sol';
import {EIP4337AccountFactory} from '../../src/eip4337-account/EIP4337AccountFactory.sol';

// Infinitism 4337 contracts
import {EntryPoint} from '@eip4337/contracts/core/EntryPoint.sol';

// Gnosis Safe contracts
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';

import './helpers/Helper4337.t.sol';

contract Module4337Test is Helper4337 {
	// Variable used for test eip4337 account
	EIP4337Account private deployed4337Account;
	address payable private deployed4337AccountAddress;

	uint256 internal mumbaiFork;
	uint256 internal fujiFork;

	bytes32 internal salt1 = keccak256('0x1');
	bytes32 internal salt2 = keccak256('0x2');

	bytes internal basicTransferPayload;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Check 4337 singelton is set in factory (base implementation for Forum 4337 accounts)
		assertEq(
			address(eip4337AccountFactory.eip4337AccountSingleton()),
			address(eip4337Singleton),
			'eip4337Singleton not set'
		);
		// Check 4337 entryPoint is set in factory
		assertEq(
			address(eip4337AccountFactory.entryPoint()),
			address(entryPoint),
			'entryPoint not set'
		);
		// Check 4337 gnosis fallback handler is set in factory
		assertEq(
			address(eip4337AccountFactory.gnosisFallbackLibrary()),
			address(handler),
			'handler not set'
		);
		// Check 4337 entryPoint is set in the singleton
		//assertEq(address(eip4337Singleton.entryPoint()), address(entryPoint), 'entryPoint not set');

		// Deploy an account to be used in tests later
		deployed4337AccountAddress = eip4337AccountFactory.createAccount(
			accountSalt(1, testSig1.signer),
			testSig1.signer
		);
		deployed4337Account = EIP4337Account(deployed4337AccountAddress);

		// Deal funds to account
		deal(deployed4337AccountAddress, 1 ether);

		// Payload used in some tests
		basicTransferPayload = buildExecutionPayload(
			alice,
			0.5 ether,
			new bytes(0),
			Enum.Operation.Call
		);

		mumbaiFork = vm.createFork(vm.envString('MUMBAI_RPC_URL'));
		fujiFork = vm.createFork(vm.envString('FUJI_RPC_URL'));
	}

	/// -----------------------------------------------------------------------
	/// Deployment tests
	/// -----------------------------------------------------------------------

	function testFactoryDeploy() public {
		// Check that the account from setup is deployed and data is set on account, and safe
		assertEq(deployed4337Account.owner()[0], testSig1.signer[0], 'owner not set');
		assertEq(deployed4337Account.owner()[1], testSig1.signer[1], 'owner not set');
		assertEq(deployed4337Account.getThreshold(), 1, 'threshold not set');
		assertEq(
			deployed4337Account.getOwners()[0],
			calculateOwnerAddress(testSig1.signer),
			'owner not set on safe'
		);
		assertEq(
			address(deployed4337Account.entryPoint()),
			address(entryPoint),
			'entry point not set'
		);
	}

	function testFactoryDeployFromEntryPoint() public {
		// Encode the calldata for the factory to create an account
		bytes memory factoryCalldata = abi.encodeWithSignature(
			'createAccount(bytes32,uint256[2])',
			salt2,
			testSig1.signer
		);

		// Prepend the address of the factory
		bytes memory initCode = abi.encodePacked(eip4337AccountFactory, factoryCalldata);

		// Calculate address in advance to use as sender
		address preCalculatedAccountAddress = (eip4337AccountFactory).getAddress(
			accountSalt(2, testSig1.signer)
		);
		// Deal funds to account
		deal(preCalculatedAccountAddress, 1 ether);
		// Cast to EIP4337Account - used to make some test assertions easier
		EIP4337Account testNew4337Account = EIP4337Account(payable(preCalculatedAccountAddress));

		// Build userop (no need for payload, use empty bytes)
		UserOperation memory userOp = buildUserOp(
			1, // use test account 1
			preCalculatedAccountAddress,
			0,
			initCode,
			new bytes(0)
		);
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOp;
		console.log('pre handle');
		// Handle userOp
		entryPoint.handleOps(userOps, payable(alice));

		// Check that the account is deployed and data is set on account, and safe
		assertEq(testNew4337Account.owner()[0], testSig1.signer[0], 'owner not set');
		assertEq(testNew4337Account.owner()[1], testSig1.signer[1], 'owner not set');
		assertEq(testNew4337Account.getThreshold(), 1, 'threshold not set');
		assertEq(
			testNew4337Account.getOwners()[0],
			calculateOwnerAddress(testSig1.signer),
			'owner not set on safe'
		);
		assertEq(
			address(testNew4337Account.entryPoint()),
			address(entryPoint),
			'entry point not set'
		);
	}

	function testCorrectAddressCrossChain() public {
		address tmpMumbai;
		address tmpFuji;

		// Fork Mumbai and create an account from a fcatory
		vm.selectFork(mumbaiFork);

		eip4337AccountFactory = new EIP4337AccountFactory(
			eip4337Singleton,
			entryPoint,
			address(handler)
		);

		// Deploy an account to be used in tests
		tmpMumbai = eip4337AccountFactory.createAccount(
			accountSalt(1, testSig1.signer),
			testSig1.signer
		);

		// Fork Fuji and create an account from a fcatory
		vm.selectFork(fujiFork);

		eip4337AccountFactory = new EIP4337AccountFactory(
			eip4337Singleton,
			entryPoint,
			address(handler)
		);

		// Deploy an account to be used in tests
		tmpFuji = eip4337AccountFactory.createAccount(
			accountSalt(1, testSig1.signer),
			testSig1.signer
		);

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
			address(entryPoint),
			'entry point not set'
		);

		// Build userop to set entrypoint to this contract as a test
		UserOperation memory userOp = buildUserOp(
			1, // use test account 1
			deployed4337AccountAddress,
			deployed4337Account.nonce(),
			new bytes(0),
			abi.encodeWithSignature('setEntryPoint(address)', address(this))
		);
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOp;

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
		UserOperation memory userOp = buildUserOp(
			2, // use test account 2
			deployed4337AccountAddress,
			deployed4337Account.nonce(),
			new bytes(0),
			basicTransferPayload
		);
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOp;

		// Check nonce before tx
		assertEq(deployed4337Account.nonce(), 0, 'nonce not correct');

		// Handle userOp
		entryPoint.handleOps(userOps, payable(address(this)));

		uint256 gas = calculateGas(userOp);

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
		UserOperation memory userOp = buildUserOp(
			1, // use test account 1
			deployed4337AccountAddress,
			deployed4337Account.nonce(),
			new bytes(0),
			payload
		);
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOp;

		// Check nonce before tx
		assertEq(deployed4337Account.nonce(), 0, 'nonce not correct');

		// Handle userOp
		entryPoint.handleOps(userOps, payable(address(this)));

		uint256 gas = calculateGas(userOp);

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
		UserOperation memory userOp = buildUserOp(
			1, // use test account 1
			deployed4337AccountAddress,
			deployed4337Account.nonce(),
			new bytes(0),
			basicTransferPayload
		);
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
			callData: basicTransferPayload,
			callGasLimit: 100000,
			verificationGasLimit: 10000000,
			preVerificationGas: 21000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: abi.encodePacked(testSig1.sig[0], testSig1.sig[1])
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

	function accountSalt(uint salt, uint[2] memory owner) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked(salt, owner));
	}
}
