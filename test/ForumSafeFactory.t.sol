// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Helers with module and safe setup
import './config/ForumModuleTestConfig.t.sol';
import './config/SafeTestConfig.t.sol';

contract ForumSafeFactoryTest is ForumModuleTestConfig, SafeTestConfig {
	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		forumSafeFactory = new ForumSafeFactory(
			alice,
			payable(address(forumSafeModuleSingleton)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory),
			address(fundraiseExtension),
			address(withdrawalExtension),
			address(0) // pfpSetter - not used in tests
		);
	}

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
	// ! THESE TESTS SHOULD BE CONVERTED TO NON 'PROPOSAL' BASED TESTS (MOST LOGIC IS THE SAME)

	// function testExtendSafeWithForumModule() public {
	// 	// Deploy a safe to test with - the module is used to simulate a safe
	// 	// making a delegate call to the factory to extend itself with a module
	// 	(ForumSafeModule testModule, GnosisSafe safe) = forumSafeFactory.deployForumSafe(
	// 		'test',
	// 		'T',
	// 		[uint32(60), uint32(12), uint32(50), uint32(80)],
	// 		voters,
	// 		initialExtensions
	// 	);

	// 	// Build paylad to extendSafeWithForumModule
	// 	bytes memory payload = abi.encodeWithSignature(
	// 		'extendSafeWithForumModule(string,string,uint32[4])',
	// 		'test2',
	// 		'test2',
	// 		[uint32(60), uint32(12), uint32(50), uint32(80)]
	// 	);

	// 	// Propose call forum module - MUST be delegate call to work
	// 	uint256 prop = proposeToForum(
	// 		testModule,
	// 		IForumSafeModuleTypes.ProposalType.CALL,
	// 		Enum.Operation.DelegateCall,
	// 		[address(forumSafeFactory)],
	// 		[uint256(0)],
	// 		[payload]
	// 	);

	// 	vm.recordLogs();

	// 	// Check modules count before processing proposal
	// 	(address[] memory mods, ) = safe.getModulesPaginated(oneAddress, 10);
	// 	assertEq(mods.length, 1, 'safe should have 1 module');

	// 	// Process prop
	// 	processProposal(prop, testModule, true);

	// 	// Check modules count after processing proposal
	// 	(address[] memory modsAfter, ) = safe.getModulesPaginated(oneAddress, 10);
	// 	assertEq(modsAfter.length, 2, 'safe should have 2 module');

	// 	Vm.Log[] memory entries = vm.getRecordedLogs();

	// 	// Extract the address of the deployed module from the logs
	// 	ForumSafeModule deployedModule = ForumSafeModule(
	// 		payable(address(uint160(uint256(entries[4].topics[1]))))
	// 	);

	// 	assertTrue(safe.isModuleEnabled(address(deployedModule)));
	// 	assertEq(deployedModule.avatar(), address(safe), 'safe not set as avatar');
	// 	assertEq(deployedModule.target(), address(safe), 'safe not set as target');
	// 	assertEq(deployedModule.owner(), address(safe), 'safe not set as owner');
	// }

	// function testCannotSetMemberLimitBelowOwnerCount() public {
	// 	// Build arrays used to seup forum module
	// 	voters.push(bob);

	// 	// Deploy a safe to test with - the module is used to simulate a safe
	// 	// making a delegate call to the factory to extend itself with a module
	// 	(ForumSafeModule testModule, GnosisSafe safe) = forumSafeFactory.deployForumSafe(
	// 		'test',
	// 		'T',
	// 		[uint32(60), uint32(12), uint32(50), uint32(80)],
	// 		voters,
	// 		initialExtensions
	// 	);

	// 	// Build paylad to extendSafeWithForumModule
	// 	// This will fail since the member limit is set to 1 but there are 2 already voters
	// 	bytes memory payload = abi.encodeWithSignature(
	// 		'extendSafeWithForumModule(string,string,uint32[4])',
	// 		'test2',
	// 		'test2',
	// 		[uint32(60), uint32(1), uint32(50), uint32(80)]
	// 	);

	// 	// Propose call forum module - MUST be delegate call to work
	// 	uint256 prop = proposeToForum(
	// 		testModule,
	// 		IForumSafeModuleTypes.ProposalType.CALL,
	// 		Enum.Operation.DelegateCall,
	// 		[address(forumSafeFactory)],
	// 		[uint256(0)],
	// 		[payload]
	// 	);

	// 	// Process prop - call will fail
	// 	processProposal(prop, testModule, false);
	// }
	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------
}
