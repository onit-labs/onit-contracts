// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GnosisSafe} from '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';
import {CompatibilityFallbackHandler} from '@gnosis.pm/safe-contracts/contracts/handler/CompatibilityFallbackHandler.sol';
import {MultiSend} from '@gnosis.pm/safe-contracts/contracts/libraries/MultiSend.sol';
import {GnosisSafeProxyFactory} from '@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol';

import {ForumSafeFactory} from '../../src/gnosis-forum/ForumSafeFactory.sol';
import {ForumSafeModule} from '../../src/gnosis-forum/ForumSafeModule.sol';

import {ERC721Test} from '../../src/Test/ERC721Test.sol';
import {ERC1155Test} from '../../src/Test/ERC1155Test.sol';

import 'forge-std/Test.sol';
import 'forge-std/StdCheats.sol';
import 'forge-std/console.sol';

contract ForumSafeFactoryTest is Test {
	// Safe contract types
	GnosisSafe private safeSingleton;
	MultiSend private multisend;
	CompatibilityFallbackHandler private handler;
	GnosisSafeProxyFactory private safeProxyFactory;
	// sigMessageLib -> get when needed for 1271 tests

	// Forum contract types
	ForumSafeFactory private forumSafeFactory;
	ForumSafeModule private forumSafeModule;

	address internal alice;
	uint256 internal alicePk;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		(alice, alicePk) = makeAddrAndKey('alice');

		safeSingleton = new GnosisSafe();
		multisend = new MultiSend();
		handler = new CompatibilityFallbackHandler();
		safeProxyFactory = new GnosisSafeProxyFactory();

		forumSafeModule = new ForumSafeModule();
		forumSafeFactory = new ForumSafeFactory(
			alice,
			payable(address(forumSafeModule)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory)
		);
	}

	/// -----------------------------------------------------------------------
	/// Test
	/// -----------------------------------------------------------------------

	function testChecSetup() public {
		console.logString('hi');
	}
}
