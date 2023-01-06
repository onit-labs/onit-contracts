// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721Test} from '../../src/test-contracts/ERC721Test.sol';
import {ERC1155Test} from '../../src/test-contracts/ERC1155Test.sol';

import './helpers/ForumSafeTestConfig.t.sol';

import 'forge-std/console.sol';

// ! Consider
// Test for handling assets sent to group directly
// Other interactions which can happen between module and safe?
// removing multicall from module if not used

contract ForumSafeModuleTest is ForumSafeTestConfig {
	ForumSafeModule private forumSafeModule;
	GnosisSafe private safe;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Deploy a forum safe from the factory
		(forumSafeModule, safe) = forumSafeFactory.deployForumSafe(
			'test',
			'T',
			[uint32(60), uint32(12), uint32(50), uint32(80)],
			voters,
			initialExtensions
		);
	}

	/// -----------------------------------------------------------------------
	/// Admin operations on Safe and Module
	/// -----------------------------------------------------------------------

	function testModuleAddsOwnerToSafe() public {}

	function testUpdateOwnerOnModule() public {}

	function testUpdateAvatarandTargetOnModule() public {}

	/// -----------------------------------------------------------------------
	/// Module execution on safe
	/// -----------------------------------------------------------------------

	function testModuleAddsOtherModuleToSafe() public {
		// Create payload to enable module (any address will do for example) on safe
		bytes memory enableModulePayload = abi.encodeWithSignature(
			'enableModule(address)',
			address(this)
		);

		console.logBool(safe.isModuleEnabled(address(forumSafeModule)));
		console.logBytes(enableModulePayload);
		console.logUint(enableModulePayload.length);

		// Encode the multisend transaction
		// (needed to delegate call from the safe as addModule is 'authorised')
		bytes memory tmp = abi.encodePacked(
			uint8(0),
			address(safe),
			uint256(0),
			uint256(enableModulePayload.length),
			bytes(enableModulePayload)
		);

		console.logBytes(tmp);

		// Create multisend payload
		bytes memory multisendPayload = abi.encodeWithSignature('multiSend(bytes)', tmp);

		console.logBytes(multisendPayload);

		// Create proposal to enable module on safe
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		processProposal(prop, forumSafeModule, true);

		// Check module is enabled on safe
		assertTrue(safe.isModuleEnabled(address(this)));
	}

	function testEnablesSafeToRescueTokensOnModule() public {} // todo is this needed? (taken from minion)

	function testRevertsIfExternalCallReverts() public {}

	function testCannotExecOnSafe() public {} // prevents calling exec method on safe via module

	function testAdds1271SigToSafe() public {}

	function testMultisendProposalViaSafe() public {}

	function testCannotExecMultisendIfPartFails() public {}

	function testCannotExecuteDifferentActionFromProposal() public {}

	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------
}
