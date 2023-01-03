// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GnosisSafe} from '@gnosis/GnosisSafe.sol';
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';
import {MultiSend} from '@gnosis/libraries/MultiSend.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';

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

	// Declare arrys used to setup forum groups
	address[] private voters = new address[](1);
	address[] private initialExtensions = new address[](1);

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		(alice, alicePk) = makeAddrAndKey('alice');

		// Deploy Safe contracts
		safeSingleton = new GnosisSafe();
		multisend = new MultiSend();
		handler = new CompatibilityFallbackHandler();
		safeProxyFactory = new GnosisSafeProxyFactory();

		// Deploy Forum contracts
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
	/// Deploy Safe with Forum
	/// -----------------------------------------------------------------------

	function testDeployForumSafe() public {
		voters[0] = alice;
		initialExtensions[0] = address(0);

		(ForumSafeModule deployedForumSafe, GnosisSafe deployedSafe) = forumSafeFactory
			.deployForumSafe(
				'test',
				'T',
				[uint32(60), uint32(12), uint32(50), uint32(80)],
				voters,
				initialExtensions
			);

		assertEq(deployedSafe.getOwners()[0], address(deployedForumSafe), 'forum not set as owner');
		assertEq(deployedForumSafe.avatar(), address(deployedSafe), 'safe not set as avatar');
		assertEq(deployedForumSafe.target(), address(deployedSafe), 'safe not set as target');
		assertEq(deployedForumSafe.owner(), address(deployedSafe), 'safe not set as owner');
		assertEq(deployedForumSafe.balanceOf(alice, 0), 1, 'alice not a member on forum group');
	}

	/// -----------------------------------------------------------------------
	/// Attach Forum Module to Existing Safe
	/// -----------------------------------------------------------------------

	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------
}
