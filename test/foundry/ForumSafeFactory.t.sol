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

		assertEq(deployedSafe.getOwners()[0], address(alice), 'alice not set as owner');
		assertEq(deployedForumSafe.avatar(), address(deployedSafe), 'safe not set as avatar');
		assertEq(deployedForumSafe.target(), address(deployedSafe), 'safe not set as target');
		assertEq(deployedForumSafe.owner(), address(deployedSafe), 'safe not set as owner');
	}

	/// -----------------------------------------------------------------------
	/// Attach Forum Module to Existing Safe
	/// -----------------------------------------------------------------------

	function testExtendSafeWithForumModule() public {
		// Create a gnosis safe
		GnosisSafe s = GnosisSafe(
			payable(
				safeProxyFactory.createProxy(
					address(safeSingleton),
					abi.encodePacked('name')
					//abi.encodePacked(_moloch, _saltNonce)
				)
			)
		);

		// Call setup on safe to enable our new module and set the module as the only signer
		s.setup(
			voters,
			voters.length,
			address(0),
			'0x',
			address(0),
			address(0),
			0,
			payable(address(0))
		);

		// Build arrays used to seup forum module
		voters[0] = alice;
		initialExtensions[0] = address(0);

		vm.prank(address(s), address(s));
		ForumSafeModule forumGroup = forumSafeFactory.extendSafeWithForumModule(
			'test',
			'test',
			[uint32(60), uint32(12), uint32(50), uint32(80)]
		);

		assertEq(s.getOwners()[0], address(alice), 'alice not set as owner');
		assertEq(forumGroup.avatar(), address(s), 'safe not set as avatar');
		assertEq(forumGroup.target(), address(s), 'safe not set as target');
		assertEq(forumGroup.owner(), address(s), 'safe not set as owner');
	}
	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------
}
