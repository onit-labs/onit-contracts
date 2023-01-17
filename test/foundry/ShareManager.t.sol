// SPDX-License-Identifier UNLICENSED
pragma solidity ^0.8.13;

import './helpers/ForumSafeTestConfig.t.sol';

import {ForumFundraiseExtension} from '../../src/gnosis-forum/extensions/fundraise/ForumFundraiseExtension.sol';
import {ForumShareManager} from '../../src/gnosis-forum/extensions/share-manager/ForumShareManager.sol';

contract TestShareManager is ForumSafeTestConfig {
	ForumShareManager shareManager;

	ForumSafeModule private forumSafeModule;
	GnosisSafe private safe;

	address private shareManagerAddress;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		fundraiseExtension = new ForumFundraiseExtension();
		shareManager = new ForumShareManager();

		// Deploy a forum safe from the factory
		(forumSafeModule, safe) = forumSafeFactory.deployForumSafe(
			'test',
			'T',
			[uint32(60), uint32(12), uint32(50), uint32(80)],
			voters,
			initialExtensions
		);

		// Set addresses for easier use in tests
		moduleAddress = address(forumSafeModule);
		safeAddress = address(safe);
		shareManagerAddress = address(shareManager);

		// Set extension with module as manager
		setExtensionWithSafeManager(new bytes(0), 1);

		// Check that the extension is enabled
		assertTrue(forumSafeModule.extensions(shareManagerAddress));
	}

	/// -----------------------------------------------------------------------
	/// Share Manager Setup
	/// -----------------------------------------------------------------------

	function testSetShareManagerExt() public {
		address[] memory managers = new address[](1);
		managers[0] = moduleAddress;
		bool[] memory settings = new bool[](1);
		settings[0] = true;

		// Abi encoded payload of managers and booleans
		bytes memory setExtensionPayload = abi.encode(managers, settings);

		// Set extension
		setExtensionWithSafeManager(setExtensionPayload, 0);

		// Check that the extension is set, and module is manager
		assertTrue(forumSafeModule.extensions(shareManagerAddress));
		assertTrue(shareManager.management(moduleAddress, moduleAddress));
	}

	function testUnsetExtension() public {
		// Unset extension
		setExtensionWithSafeManager(new bytes(0), 1);

		// Check that the extension is set, and module is manager
		assertFalse(forumSafeModule.extensions(shareManagerAddress));
	}

	function testCannotSetArrayMissmatch() public {
		// Abi encoded payload of managers and booleans
		bytes memory setExtensionPayload = abi.encode([moduleAddress], [true, false]);

		// Encode paylaod to set module as a manager
		bytes memory payload = abi.encodeWithSignature('setExtension(bytes)', setExtensionPayload);

		// Propose to set the extension
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumSafeModuleTypes.ProposalType.EXTENSION,
			Enum.Operation.Call,
			[address(shareManager)],
			[uint256(0)],
			[payload]
		);

		processProposal(prop, forumSafeModule, false);
	}

	/// -----------------------------------------------------------------------
	/// Share Manager Management
	/// -----------------------------------------------------------------------

	function testMintAliceShares() public {
		address[] memory managers = new address[](1);
		managers[0] = moduleAddress;
		bool[] memory settings = new bool[](1);
		settings[0] = true;

		// Abi encoded payload of managers and booleans
		bytes memory setExtensionPayload = abi.encode(managers, settings);

		// Encode paylaod to set module as a manager
		bytes memory payload = abi.encodeWithSignature('setExtension(bytes)', setExtensionPayload);

		// Set extension
		setExtensionWithSafeManager(setExtensionPayload, 0);

		// Build payload to mint 100 shares for Alice
		bytes memory mintPayload = abi.encode(alice, 1, true);

		// Payload for callExtension proposal
		bytes memory callExtPayload = abi.encodeWithSignature(
			'callExtension(address, bytes[]',
			moduleAddress,
			[mintPayload]
		);

		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumSafeModuleTypes.ProposalType.CALL,
			Enum.Operation.DelegateCall,
			[shareManagerAddress],
			[uint256(0)],
			[callExtPayload]
		);

		processProposal(prop, forumSafeModule, true);

		// Check balances
		assertEq(forumSafeModule.balanceOf(alice, TOKEN), 1 ether + 1);
		assertEq(forumSafeModule.totalSupply(), 1 ether + 1);
	}

	// -----------------------------------------------------------------------
	// Utils
	// -----------------------------------------------------------------------

	function setExtensionWithSafeManager(bytes memory payload, uint256 active) internal {
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumSafeModuleTypes.ProposalType.EXTENSION,
			Enum.Operation.Call,
			[shareManagerAddress],
			[active],
			[payload]
		);

		processProposal(prop, forumSafeModule, true);
	}
}
