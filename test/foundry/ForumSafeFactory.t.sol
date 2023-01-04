// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './helpers/ForumSafeTestConfig.t.sol';

contract ForumSafeFactoryTest is ForumSafeTestConfig {
	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {}

	/// -----------------------------------------------------------------------
	/// Deploy Safe with Forum
	/// -----------------------------------------------------------------------

	function testDeployForumSafe() public {
		// Build arrays used to seup forum module
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
