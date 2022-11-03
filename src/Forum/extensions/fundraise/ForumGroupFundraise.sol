// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {SafeTransferLib} from '../../../libraries/SafeTransferLib.sol';

import {ReentrancyGuard} from '../../../utils/ReentrancyGuard.sol';

import {IForumGroup} from '../../../interfaces/IForumGroup.sol';

/**
 * @title ForumGroupFundraise
 * @notice Contract that implements a round of fundraising from all DAO members
 * @dev Version 1 - AVAX only fundraise. All members must contribute
 */
contract ForumGroupFundraise is ReentrancyGuard {
	using SafeTransferLib for address;

	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event NewFundContribution(address indexed groupAddress, address indexed proposer, uint256 value);

	event FundRoundCancelled(address indexed groupAddress);

	event FundRoundReleased(
		address indexed groupAddress,
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
	// This is used to determin how many token to mint for eac contributor
	struct Fund {
		address[] contributors;
		uint256 individualContribution;
		uint256 valueNumerator;
		uint256 valueDenominator;
	}

	uint256 private constant MEMBERSHIP = 0;
	uint256 private constant TOKEN = 1;

	mapping(address => Fund) private funds;

	mapping(address => mapping(address => bool)) public contributionTracker;

	/// -----------------------------------------------------------------------
	/// Fundraise Logic
	/// -----------------------------------------------------------------------

	/**
	 * @notice Initiate a round of fundraising
	 * @param groupAddress Address of group
	 */
	function initiateFundRound(
		address groupAddress,
		uint256 valueNumerator,
		uint256 valueDenominator
	) public payable virtual nonReentrant {
		// Only members can start a fund.
		if (IForumGroup(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		if (funds[groupAddress].individualContribution != 0) revert OpenFund();

		// No gas saving to use Fund({}) format, and since we need to push to the arry, we assign each element individually.
		funds[groupAddress].contributors.push(msg.sender);
		funds[groupAddress].individualContribution = msg.value;
		funds[groupAddress].valueNumerator = valueNumerator;
		funds[groupAddress].valueDenominator = valueDenominator;
		contributionTracker[groupAddress][msg.sender] = true;

		emit NewFundContribution(groupAddress, msg.sender, msg.value);
	}

	/**
	 * @notice Submit a fundraise contribution
	 * @param groupAddress Address of group
	 */
	function submitFundContribution(address groupAddress) public payable virtual nonReentrant {
		// Only members can contribute to the fund
		if (IForumGroup(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		// Can only contribute once per fund
		if (contributionTracker[groupAddress][msg.sender]) revert IncorrectContribution();

		if (msg.value != funds[groupAddress].individualContribution) revert IncorrectContribution();

		if (funds[groupAddress].individualContribution == 0) revert FundraiseMissing();

		funds[groupAddress].contributors.push(msg.sender);
		contributionTracker[groupAddress][msg.sender] = true;

		emit NewFundContribution(groupAddress, msg.sender, msg.value);
	}

	/**
	 * @notice Cancel a fundraise and return funds to contributors
	 * @param groupAddress Address of group
	 */
	function cancelFundRound(address groupAddress) public virtual nonReentrant {
		if (IForumGroup(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0) revert NotMember();

		Fund storage fund = funds[groupAddress];

		// Only groupAddress or proposer can cancel the fundraise.
		if (!(msg.sender == groupAddress || msg.sender == fund.contributors[0])) revert NotProposer();

		// Return funds from escrow
		for (uint256 i; i < fund.contributors.length; ) {
			payable(fund.contributors[i]).transfer(fund.individualContribution);
			contributionTracker[groupAddress][fund.contributors[i]] = false;

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete funds[groupAddress];

		emit FundRoundCancelled(groupAddress);
	}

	/**
	 * @notice Process the fundraise, sending AVAX to group and minting tokens to contributors
	 * @param groupAddress Address of group
	 */
	function processFundRound(address groupAddress) public virtual nonReentrant {
		Fund memory fund = funds[groupAddress];

		if (funds[groupAddress].individualContribution == 0) revert FundraiseMissing();

		uint256 memberCount = fund.contributors.length;

		// We adjust the number of shares distributed based on the unitValue of group tokens
		// This ensures that members get a fair number of tokens given the value of the treasury at any time
		uint256 adjustedContribution = (fund.individualContribution * fund.valueDenominator) /
			fund.valueNumerator;

		if (memberCount != IForumGroup(groupAddress).memberCount()) revert MembersMissing();

		groupAddress._safeTransferETH(fund.individualContribution * memberCount);

		for (uint256 i; i < memberCount; ) {
			// Mint member an share of tokens equal to their contribution and reset their status in the tracker
			IForumGroup(groupAddress).mintShares(fund.contributors[i], TOKEN, adjustedContribution);
			contributionTracker[groupAddress][fund.contributors[i]] = false;

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete funds[groupAddress];

		emit FundRoundReleased(groupAddress, fund.contributors, fund.individualContribution);
	}

	/**
	 * @notice Get the details of a fundraise
	 * @param groupAddress Address of group
	 * @return fundDetails The fundraise requested
	 */
	function getFund(address groupAddress) public view returns (Fund memory fundDetails) {
		return funds[groupAddress];
	}
}
