// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721Test} from '../../src/Test/ERC721Test.sol';
import {ERC1155Test} from '../../src/Test/ERC1155Test.sol';

import './helpers/ForumSafeTestConfig.t.sol';

// ! Consider
// Test for handling assets sent to group directly
// Other interactions which can happen between module and safe?
// removing multicall from module if not used

contract ForumSafeModuleTest is ForumSafeTestConfig {
	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {}

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
		// create payload to add module
		// propose to group
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
