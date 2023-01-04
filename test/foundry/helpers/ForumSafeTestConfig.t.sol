// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GnosisSafe} from '@gnosis/GnosisSafe.sol';
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';
import {MultiSend} from '@gnosis/libraries/MultiSend.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';

import {ForumSafeFactory} from '../../../src/gnosis-forum/ForumSafeFactory.sol';
import {ForumSafeModule} from '../../../src/gnosis-forum/ForumSafeModule.sol';

import {ERC721Test} from '../../../src/Test/ERC721Test.sol';
import {ERC1155Test} from '../../../src/Test/ERC1155Test.sol';

import 'forge-std/Test.sol';
import 'forge-std/StdCheats.sol';
import 'forge-std/console.sol';

abstract contract ForumSafeTestConfig is Test {
	// Safe contract types
	GnosisSafe internal safeSingleton = new GnosisSafe();
	MultiSend internal multisend = new MultiSend();
	CompatibilityFallbackHandler internal handler = new CompatibilityFallbackHandler();
	GnosisSafeProxyFactory internal safeProxyFactory = new GnosisSafeProxyFactory();
	// sigMessageLib -> get when needed for 1271 tests

	// Forum contract types
	ForumSafeModule internal forumSafeModule = new ForumSafeModule();
	ForumSafeFactory internal forumSafeFactory =
		new ForumSafeFactory(
			alice,
			payable(address(forumSafeModule)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory)
		);

	address internal alice;
	uint256 internal alicePk;

	// Declare arrys used to setup forum groups
	address[] internal voters = new address[](1);
	address[] internal initialExtensions = new address[](1);

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------
}
