// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import 'hardhat/console.sol';
import {SafeTransferLib} from '../libraries/SafeTransferLib.sol';

import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';

import {IForumGroup} from '../interfaces/IForumGroup.sol';
import {IForumGroupFactoryV2} from '../interfaces/IForumGroupFactoryV2.sol';
import {IForumGroupFactory} from '../interfaces/IForumGroupFactory.sol';

/**
 * @title Forum Crowdfund
 * @notice Lets people pool funds to purchase an item as a group, deploying a Forum group for management
 */
contract ForumCrowdfund is ReentrancyGuard {
	using SafeTransferLib for address;

	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event NewCrowdfund(string indexed groupName);

	event FundsAdded(string indexed groupName, address contributor, uint256 contribution);

	event Cancelled(string indexed groupName);

	event Processed(string indexed groupName, address indexed groupAddress);

	/// -----------------------------------------------------------------------
	/// Errors
	/// -----------------------------------------------------------------------

	error NotProposer();

	error NotMember();

	error MembersMissing();

	error MissingCrowdfund();

	error MemberLimitReached();

	error IncorrectContribution();

	error OpenFund();

	/// -----------------------------------------------------------------------
	/// Crowdfund Storage
	/// -----------------------------------------------------------------------

	struct CrowdfundParameters {
		address targetContract;
		uint256 targetPrice;
		uint32 deadline;
		string groupName;
		string symbol;
		bytes payload;
	}

	struct Crowdfund {
		address[] contributors;
		mapping(address => uint256) contributions;
		CrowdfundParameters parameters;
	}

	address public forumFactory;

	mapping(bytes32 => Crowdfund) private crowdfunds;

	mapping(address => mapping(address => bool)) public contributionTracker;

	/// -----------------------------------------------------------------------
	/// Constructor
	/// -----------------------------------------------------------------------

	constructor(address forumFactory_) {
		forumFactory = forumFactory_;
	}

	/// -----------------------------------------------------------------------
	/// Fundraise Logic
	/// -----------------------------------------------------------------------

	// todo consider commission and fit into target value
	/**
	 * @notice Initiate a crowdfund to buy an asset
	 * @param parameters the parameters struct for the crowdfund
	 */
	function initiateCrowdfund(CrowdfundParameters calldata parameters)
		public
		payable
		virtual
		nonReentrant
	{
		// Using the bytes32 hash of the name as mapping key saves ~250 gas per write
		bytes32 groupNameHash = keccak256(abi.encode(parameters.groupName));

		// maybe check the amount?
		// maybe check sender?
		if (crowdfunds[groupNameHash].parameters.deadline != 0) revert OpenFund();

		// No gas saving to use crowdfund({}) format, and since we need to push to the arry, we assign each element individually.
		crowdfunds[groupNameHash].parameters = parameters;
		crowdfunds[groupNameHash].contributors.push(msg.sender);
		crowdfunds[groupNameHash].contributions[msg.sender] = msg.value;

		emit NewCrowdfund(parameters.groupName);
	}

	/**
	 * @notice Submit a crowdfund contribution
	 * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
	 */
	function submitContribution(bytes32 groupNameHash) public payable virtual nonReentrant {
		Crowdfund storage fund = crowdfunds[groupNameHash];

		// ! consider a check on contributions and target price

		if (fund.parameters.deadline == 0) revert MissingCrowdfund();

		if (fund.contributors.length == 100) revert MemberLimitReached();

		if (fund.contributions[msg.sender] == 0) {
			fund.contributors.push(msg.sender);
			fund.contributions[msg.sender] = msg.value;
		} else crowdfunds[groupNameHash].contributions[msg.sender] += msg.value;

		emit FundsAdded(fund.parameters.groupName, msg.sender, msg.value);
	}

	/**
	 * @notice Cancel a crowdfund and return funds to contributors
	 * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
	 */
	function cancelCrowdfund(bytes32 groupNameHash) public virtual nonReentrant {
		Crowdfund storage fund = crowdfunds[groupNameHash];

		if (fund.parameters.deadline > block.timestamp) revert OpenFund();

		// Return funds from escrow
		for (uint256 i; i < fund.contributors.length; ) {
			console.logAddress(fund.contributors[i]);
			console.logUint(fund.contributions[msg.sender]);
			payable(fund.contributors[i]).transfer(fund.contributions[msg.sender]);

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		// ! better clearing of this is needed now we have  a mapping
		delete crowdfunds[groupNameHash];

		emit Cancelled(fund.parameters.groupName);
	}

	/**
	 * @notice Process a crowdfund and deploy a Forum group
	 * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
	 */
	function processCrowdfund(bytes32 groupNameHash) public virtual nonReentrant {
		Crowdfund storage fund = crowdfunds[groupNameHash];

		// todo consider block on deadline
		// if (fund.parameters.deadline > block.timestamp) revert OpenFund();

		// todo check targetValue is raised

		// customExtension of this address allows this contract to mint each member shares
		address[] memory customExtensions = new address[](1);
		customExtensions[0] = address(this);

		// Deploy the Forum group to hold the NFT as a group
		// Default settings of 3 days vote period, 100 member limit, 80% member & token vote thresholds
		IForumGroup forumGroup = IForumGroupFactoryV2(forumFactory).deployGroup(
			fund.parameters.groupName,
			fund.parameters.symbol,
			fund.contributors,
			[uint32(3 days), uint32(100), uint32(80), uint32(80)],
			customExtensions
		);

		// ! consider execution / target value check
		// ! consider commission
		// !!! prevent same user being added twice
		// execute the tx with payload
		(, bytes memory result) = (fund.parameters.targetContract).call{
			value: fund.parameters.targetPrice
		}(fund.parameters.payload);

		// distribute the group funds
		for (uint256 i; i < fund.contributors.length; ) {
			forumGroup.mintShares(fund.contributors[i], 0, 1);
			forumGroup.mintShares(fund.contributors[i], 1, fund.contributions[msg.sender]);

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		delete crowdfunds[groupNameHash];

		emit Processed(fund.parameters.groupName, address(forumGroup));
	}

	/**
	 * @notice Get the details of a crowdfund
	 * @param groupNameHash hash of the group name
	 */
	function getCrowdfund(bytes32 groupNameHash)
		public
		view
		returns (
			CrowdfundParameters memory details,
			address[] memory contributors,
			uint256[] memory contributions
		)
	{
		Crowdfund storage fund = crowdfunds[groupNameHash];

		contributions = new uint256[](crowdfunds[groupNameHash].contributors.length);
		for (uint256 i; i < fund.contributors.length; ) {
			contributions[i] = fund.contributions[fund.contributors[i]];
			unchecked {
				++i;
			}
		}
		(details, contributors, contributions) = (fund.parameters, fund.contributors, contributions);
	}
}
