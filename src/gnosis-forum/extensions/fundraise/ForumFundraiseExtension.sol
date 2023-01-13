// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {SafeTransferLib} from '../../../libraries/SafeTransferLib.sol';

import {ReentrancyGuard} from '../../../utils/ReentrancyGuard.sol';

import {IForumSafeModule} from '../../../interfaces/IForumSafeModule.sol';

import {SafeHelper} from '../../../utils/SafeHelper.sol';

/**
 * @title ForumGroupFundraise
 * @notice Contract that implements a round of fundraising from all DAO members
 * @dev Version 2 - AVAX only fundraise. All members must contribute. Funds go to safe
 */
contract ForumFundraiseExtension is ReentrancyGuard {
	using SafeTransferLib for address;

	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event NewFundContribution(address indexed forumModule, address indexed proposer, uint256 value);

	event FundRoundCancelled(address indexed forumModule);

	event FundRoundReleased(
		address indexed forumModule,
		address[] contributors,
		uint256 individualContribution
	);

	/// -----------------------------------------------------------------------
	/// Errors
	/// -----------------------------------------------------------------------

	error NotProposer();

	error NotMember();

	error MembersMissing();

	error FundraiseMissing();

	error IncorrectContribution();

	error OpenFund();

	/// -----------------------------------------------------------------------
	/// Fundraise Storage
	/// -----------------------------------------------------------------------

	// valueNumerator and valueDenominator combine to form unitValue of treasury tokens
	// This is used to determine how many token to mint for each contributor
	struct Fund {
		address[] contributors;
		uint256 individualContribution;
		uint256 valueNumerator;
		uint256 valueDenominator;
	}

	// Consider a variable token, allowing groups to have different tiers of member
	uint256 private constant TOKEN = 0;

	mapping(address => Fund) private funds;

	mapping(address => mapping(address => bool)) public contributionTracker;

	/// -----------------------------------------------------------------------
	/// Fundraise Logic
	/// -----------------------------------------------------------------------

	/**
	 * @notice Initiate a round of fundraising
	 * @param forumModule Address of module tracking ownership
	 * @param valueNumerator Numerator of unitValue
	 * @param valueDenominator Denominator of unitValue
	 */
	function initiateFundRound(
		address forumModule,
		uint256 valueNumerator,
		uint256 valueDenominator
	) public payable virtual nonReentrant {
		// Only members can start a fund.
		if (!SafeHelper(forumModule).isOwner(msg.sender)) revert NotMember();

		if (funds[forumModule].individualContribution != 0) revert OpenFund();

		// No gas saving to use Fund({}) format, and since we need to push to the arry, we assign each element individually.
		funds[forumModule].contributors.push(msg.sender);
		funds[forumModule].individualContribution = msg.value;
		funds[forumModule].valueNumerator = valueNumerator;
		funds[forumModule].valueDenominator = valueDenominator;
		contributionTracker[forumModule][msg.sender] = true;

		emit NewFundContribution(forumModule, msg.sender, msg.value);
	}

	/**
	 * @notice Submit a fundraise contribution
	 * @param forumModule Address of module tracking ownership
	 */
	function submitFundContribution(address forumModule) public payable virtual nonReentrant {
		// Only members can contribute to the fund
		if (!SafeHelper(forumModule).isOwner(msg.sender)) revert NotMember();

		// Can only contribute once per fund
		if (contributionTracker[forumModule][msg.sender]) revert IncorrectContribution();

		if (msg.value != funds[forumModule].individualContribution) revert IncorrectContribution();

		if (funds[forumModule].individualContribution == 0) revert FundraiseMissing();

		funds[forumModule].contributors.push(msg.sender);
		contributionTracker[forumModule][msg.sender] = true;

		emit NewFundContribution(forumModule, msg.sender, msg.value);
	}

	/**
	 * @notice Cancel a fundraise and return funds to contributors
	 * @param forumModule Address of module tracking ownership
	 */
	function cancelFundRound(address forumModule) public virtual nonReentrant {
		if (!SafeHelper(forumModule).isOwner(msg.sender)) revert NotMember();

		Fund storage fund = funds[forumModule];

		// Only forumModule or proposer can cancel the fundraise.
		if (!(msg.sender == forumModule || msg.sender == fund.contributors[0]))
			revert NotProposer();

		// Return funds from escrow
		for (uint256 i; i < fund.contributors.length; ) {
			contributionTracker[forumModule][fund.contributors[i]] = false;
			payable(fund.contributors[i]).transfer(fund.individualContribution);

			// Members will not overflow maxint
			unchecked {
				++i;
			}
		}

		delete funds[forumModule];

		emit FundRoundCancelled(forumModule);
	}

	/**
	 * @notice Process the fundraise, sending AVAX to group and minting tokens to contributors
	 * @param forumModule Address of module tracking ownership
	 */
	function processFundRound(address forumModule) public virtual nonReentrant {
		Fund memory fund = funds[forumModule];

		if (funds[forumModule].individualContribution == 0) revert FundraiseMissing();

		uint256 memberCount = fund.contributors.length;

		// We adjust the number of shares distributed based on the unitValue of group tokens
		// This ensures that members get a fair number of tokens given the value of the treasury at any time
		uint256 adjustedContribution = (fund.individualContribution * fund.valueDenominator) /
			fund.valueNumerator;

		if (memberCount != SafeHelper(forumModule).getOwners().length) revert MembersMissing();

		// Transfer avax to the group safe
		SafeHelper(forumModule).target()._safeTransferETH(
			fund.individualContribution * memberCount
		);

		// Mint tokens to each member
		for (uint256 i; i < memberCount; ) {
			// Mint member a share of tokens equal to their contribution and reset their status in the tracker
			IForumSafeModule(forumModule).mintShares(
				fund.contributors[i],
				TOKEN,
				adjustedContribution
			);
			contributionTracker[forumModule][fund.contributors[i]] = false;

			// Members will not overflow maxint
			unchecked {
				++i;
			}
		}

		delete funds[forumModule];

		emit FundRoundReleased(forumModule, fund.contributors, fund.individualContribution);
	}

	/**
	 * @notice Get the details of a fundraise
	 * @param forumModule Address of module tracking ownership
	 * @return fundDetails The fundraise requested
	 * @dev Required as public getter fn on funds won't return array
	 */
	function getFund(address forumModule) public view returns (Fund memory fundDetails) {
		return funds[forumModule];
	}
}
