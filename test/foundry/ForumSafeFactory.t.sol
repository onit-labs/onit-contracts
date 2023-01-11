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
		// Deploy a safe to work with
		(ForumSafeModule deployedForumSafe, GnosisSafe safe) = forumSafeFactory.deployForumSafe(
			'test',
			'T',
			[uint32(60), uint32(12), uint32(50), uint32(80)],
			voters,
			initialExtensions
		);

		// Build paylad to extendSafeWithForumModule
		bytes memory payload = abi.encodeWithSignature(
			'extendSafeWithForumModule(string,string,uint32[4])',
			'test2',
			'test2',
			[uint32(60), uint32(12), uint32(50), uint32(80)]
		);

		// Propose call forum module - MUST be delegate call to work
		uint256 prop = proposeToForum(
			deployedForumSafe,
			IForumSafeModuleTypes.ProposalType.CALL,
			Enum.Operation.DelegateCall,
			[address(forumSafeFactory)],
			[uint256(0)],
			[payload]
		);

		vm.recordLogs();

		// Check modules count before processing proposal
		(address[] memory mods, ) = safe.getModulesPaginated(
			0x0000000000000000000000000000000000000001,
			10
		);
		assertEq(mods.length, 1, 'safe should have 1 module');

		//process prop
		processProposal(prop, deployedForumSafe, true);

		// Check modules count before processing proposal
		(address[] memory modsAfter, ) = safe.getModulesPaginated(
			0x0000000000000000000000000000000000000001,
			10
		);
		assertEq(modsAfter.length, 2, 'safe should have 2 module');

		Vm.Log[] memory entries = vm.getRecordedLogs();

		// (address[] memory mods, address n) = safe.getModulesPaginated(address(0), 1);
		// console.logAddress(mods[0]);
		// assertTrue(safe.isModuleEnabled(address(deployedModule)));
		// assertTrue(safe.isModuleEnabled(address(forumGroup)));
		// assertEq(safe.getOwners()[0], address(alice), 'alice not set as owner');
		// assertEq(forumGroup.avatar(), address(safe), 'safe not set as avatar');
		// assertEq(forumGroup.target(), address(safe), 'safe not set as target');
		// assertEq(forumGroup.owner(), address(safe), 'safe not set as owner');
	}
	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------
}
