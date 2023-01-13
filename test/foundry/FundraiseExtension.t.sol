// SPDX-License-Identifier UNLICENSED
pragma solidity ^0.8.13;

//import {BasicTestConfig} from './helpers/BasicTestConfig.t.sol';
import './helpers/ForumSafeTestConfig.t.sol';

import {ForumFundraiseExtension} from '../../src/gnosis-forum/extensions/fundraise/ForumFundraiseExtension.sol';

contract TestFundraiseExtension is ForumSafeTestConfig {
	// ForumFundraiseExtension fundraiseExtension;
	ForumSafeModule internal forumModule;
	GnosisSafe internal safe;

	address internal fundraiseAddress;
	address internal moduleAddress;
	address internal safeAddress;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Deploy fundraise extension
		fundraiseExtension = new ForumFundraiseExtension();

		// Add bob to voters, alongside alice
		voters.push(bob);

		// Use factory to deploy a safe
		(forumModule, safe) = forumSafeFactory.deployForumSafe(
			'test',
			'T',
			[uint32(60), uint32(12), uint32(50), uint32(80)],
			voters,
			initialExtensions
		);

		fundraiseAddress = address(fundraiseExtension);
		moduleAddress = address(forumModule);
		safeAddress = address(safe);

		// Proposal to enable the fundraise extension on the forum module
		uint256 prop = proposeToForum(
			forumModule,
			IForumSafeModuleTypes.ProposalType.EXTENSION,
			Enum.Operation.DelegateCall,
			[address(fundraiseExtension)],
			[uint256(1)],
			[new bytes(0)]
		);

		processProposal(prop, forumModule, true);

		// Check that the extension is enabled
		assertTrue(forumModule.extensions(address(fundraiseExtension)));
	}

	/// -----------------------------------------------------------------------
	/// Fundraise
	/// -----------------------------------------------------------------------

	function testInitiateFundRound() public {
		// Initiate fund round
		vm.prank(alice);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 1, 1);

		// Check that the fund round is open
		ForumFundraiseExtension.Fund memory fund = fundraiseExtension.getFund(moduleAddress);
		assertTrue(fund.contributors[0] == alice);
		assertTrue(fund.individualContribution == 1 ether);
		assertTrue(fund.valueNumerator == 1);
		assertTrue(fund.valueDenominator == 1);
	}

	function testProcessFundraise() public {
		// Fundraise
		vm.prank(alice);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 1, 1);

		// Bob contributes to round
		vm.prank(bob);
		fundraiseExtension.submitFundContribution{value: 1 ether}(moduleAddress);

		// Check updated contributors
		ForumFundraiseExtension.Fund memory fund = fundraiseExtension.getFund(moduleAddress);
		assertTrue(fund.contributors[0] == alice);
		assertTrue(fund.contributors[1] == bob);
		assertTrue(fund.contributors.length == 2);

		// Process fund round
		fundraiseExtension.processFundRound(moduleAddress);

		// Check that the fund round is closed
		ForumFundraiseExtension.Fund memory emptyFund = fundraiseExtension.getFund(moduleAddress);
		assertTrue(emptyFund.contributors.length == 0);
		assertTrue(emptyFund.individualContribution == 0);
		assertTrue(emptyFund.valueNumerator == 0);
		assertTrue(emptyFund.valueDenominator == 0);

		// Check that the safe has received the funds
		assertTrue(address(safeAddress).balance == 2 ether);

		// Check members have been minted tokens
		assertEq(forumModule.balanceOf(alice, 0), 1 ether);
		assertEq(forumModule.balanceOf(bob, 0), 1 ether);
	}

	function testProcessFundraiseWithUnitValueMultiplier() public {
		vm.prank(alice);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 2, 1);
		vm.prank(bob);
		fundraiseExtension.submitFundContribution{value: 1 ether}(moduleAddress);

		// Process fund round
		fundraiseExtension.processFundRound(moduleAddress);

		// Check that the safe has received the funds
		assertTrue(address(safeAddress).balance == 2 ether);

		// Check members have been minted tokens in correct proportion
		assertEq(forumModule.balanceOf(alice, 0), 0.5 ether);
		assertEq(forumModule.balanceOf(bob, 0), 0.5 ether);
	}

	function testRevertIfNonMemberInitiatesFundraise() public {
		// Initiate fund round
		vm.expectRevert(bytes4(keccak256('NotMember()')));
		vm.prank(carl);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 1, 1);
	}

	function testRevertIfFundIsAlreadyOpen() public {
		vm.prank(alice);
		fundraiseExtension.initiateFundRound{value: 0.5 ether}(moduleAddress, 1, 1);

		// Initiate fund round again
		vm.prank(alice);
		vm.expectRevert(bytes4(keccak256('OpenFund()')));
		fundraiseExtension.initiateFundRound{value: 0.5 ether}(moduleAddress, 1, 1);
	}

	function testRevertIfIncorrectValueSent() public {
		vm.prank(alice);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 1, 1);

		vm.expectRevert(bytes4(keccak256('IncorrectContribution()')));
		vm.prank(bob);
		fundraiseExtension.submitFundContribution{value: 0.5 ether}(moduleAddress);
	}

	// This error should only be thrown if fund is attempted with value 0
	// It should be caught by the individual contribution not being set first
	function testRevertIfNoFundIsOpen() public {
		vm.expectRevert(bytes4(keccak256('FundraiseMissing()')));
		vm.prank(alice);
		fundraiseExtension.submitFundContribution{value: 0}(moduleAddress);
	}

	function testRevertIfNotAllMembersHaveContributed() public {
		vm.startPrank(alice);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 1, 1);

		// Process fund round
		vm.expectRevert(bytes4(keccak256('MembersMissing()')));
		fundraiseExtension.processFundRound(moduleAddress);
	}

	function testRevertIfNonGroupMemberTakingPart() public {
		vm.prank(alice);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 1, 1);

		// Carl contributes to round
		vm.expectRevert(bytes4(keccak256('NotMember()')));
		vm.prank(carl);
		fundraiseExtension.submitFundContribution{value: 1 ether}(moduleAddress);
	}

	function testRevertIfUserIsDepositingTwice() public {
		// Bob initiates round
		vm.startPrank(bob);
		fundraiseExtension.initiateFundRound{value: 0.5 ether}(moduleAddress, 1, 1);

		// Bob contributes to round again
		vm.expectRevert(bytes4(keccak256('IncorrectContribution()')));
		fundraiseExtension.submitFundContribution{value: 0.5 ether}(moduleAddress);
	}

	function testCancelRound() public {
		// Fundraise
		vm.prank(alice);
		fundraiseExtension.initiateFundRound{value: 1 ether}(moduleAddress, 1, 1);

		// Bob contributes to round
		vm.prank(bob);
		fundraiseExtension.submitFundContribution{value: 1 ether}(moduleAddress);

		// Cancel round
		vm.prank(alice);
		fundraiseExtension.cancelFundRound(moduleAddress);

		// Check that the fund round is closed
		ForumFundraiseExtension.Fund memory emptyFund = fundraiseExtension.getFund(moduleAddress);
		assertTrue(emptyFund.contributors.length == 0);
		assertTrue(emptyFund.individualContribution == 0);
		assertTrue(emptyFund.valueNumerator == 0);
		assertTrue(emptyFund.valueDenominator == 0);
	}
}
