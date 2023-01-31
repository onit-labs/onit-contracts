// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// Forum 4337 contracts
import {EIP4337Account} from '../../src/eip4337-account/EIP4337Account.sol';
import {EIP4337AccountFactory} from '../../src/eip4337-account/EIP4337AccountFactory.sol';

// Infinitism 4337 contracts
import {EntryPoint} from '@eip4337/contracts/core/EntryPoint.sol';

// Gnosis Safe contracts
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';

import {BasicTestConfig} from './helpers/BasicTestConfig.t.sol';

// factory to create proxy. check init, check address (especially cross chain)

contract Module4337Test is BasicTestConfig {
	EIP4337Account private eip4337Singleton;
	EIP4337AccountFactory private eip4337AccountFactory;
	EntryPoint private entryPoint;
	CompatibilityFallbackHandler private compatibilityFallbackHandler;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		eip4337Singleton = new EIP4337Account();
		compatibilityFallbackHandler = new CompatibilityFallbackHandler();
		eip4337AccountFactory = new EIP4337AccountFactory(
			eip4337Singleton,
			address(compatibilityFallbackHandler)
		);
	}

	/// -----------------------------------------------------------------------
	/// Tests
	/// -----------------------------------------------------------------------

	function testFactoryDeploy() public {
		eip4337AccountFactory.createAccount(
			1,
			[
				0xd3c6949ab309ff80296ffb17cd2a5298ec23ad7f1fda03ca70f12353987303de,
				0x42c164839f37f10fb2e6e5649c046a473a8d4db61d0602433fe32484d1c2d8d3
			]
		);
	}

	function testFactoryDeployFromEntryPoint() public {}
}

// {
//     "r": "0x535b670719b8510bcf71a9713c23f0dadff3ec73bca56e472d01976ca16d88b7",
//     "s": "0xb4b64109a6a35302be6297bc0c7444e117c6e0185caa71d11486ad04f33f8ddd",
//     "x": "0xd3c6949ab309ff80296ffb17cd2a5298ec23ad7f1fda03ca70f12353987303de",
//     "y": "0x42c164839f37f10fb2e6e5649c046a473a8d4db61d0602433fe32484d1c2d8d3",
//     "messageHash": "0xf2424746de28d3e593fb6af9c8dff6d24de434350366e60312aacfe79dae94a8"
// }
