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
	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Check 4337 singelton is set in factory
		assertEq(
			address(eip4337AccountFactory.eip4337AccountSingleton()),
			address(eip4337Singleton),
			'factory already set'
		);
		// Check 4337 gnosis fallback is set in factory
		assertEq(
			address(eip4337AccountFactory.gnosisFallbackLibrary()),
			address(handler),
			'factory already set'
		);
	}

	/// -----------------------------------------------------------------------
	/// Deployment tests
	/// -----------------------------------------------------------------------

	function testFactoryDeploy() public {
		address payable account = eip4337AccountFactory.createAccount(1, testSig1.signer);

		EIP4337Account deployed4337Account = EIP4337Account(account);

		// Check that the account is deployed and data is set on account, and safe
		assertEq(deployed4337Account.owner()[0], testSig1.signer[0], 'owner not set');
		assertEq(deployed4337Account.owner()[1], testSig1.signer[1], 'owner not set');
		assertEq(
			deployed4337Account.getOwners()[0],
			address(uint160(testSig1.signer[0])),
			'owner not set on safe'
		);
		assertEq(
			address(deployed4337Account.entryPoint()),
			address(entryPoint),
			'entry point not set'
		);
	}

	function testFactoryDeployFromEntryPoint() public {
		// Encode the calldata for the factory
		bytes memory factoryCalldata = abi.encodeWithSignature(
			'createAccount(uint,uint[2])',
			1,
			testSig1.signer
		);

		// Prepend the address of the factory
		bytes memory initCode = abi.encodePacked(
			abi.encodePacked(eip4337AccountFactory),
			factoryCalldata
		);

		// static call factory to get address to use as sender
		address tmp = (eip4337AccountFactory).getAddress(1, testSig1.signer);

		console.log(tmp);
	}

	/// -----------------------------------------------------------------------
	/// Execution tests
	/// -----------------------------------------------------------------------

	// Test a basic transfer and check nonce
	function testTransfer() public {}
}
