// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {Owned} from '../utils/Owned.sol';
import {NFTreceiver} from '../utils/NFTreceiver.sol';
import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';

import {IForumGroup} from '../interfaces/IForumGroup.sol';
import {IForumGroupFactory} from '../interfaces/IForumGroupFactory.sol';
import {ICrowdfundExecutionManager} from '../interfaces/ICrowdfundExecutionManager.sol';

/**
 * @title Forum Crowdfund
 * @notice Lets people pool funds to purchase an item as a group, deploying a Forum group for management
 */
contract ForumCrowdfund is ReentrancyGuard, Owned, NFTreceiver {
	/// -----------------------------------------------------------------------
	/// Events
	/// -----------------------------------------------------------------------

	event NewCrowdfund(string groupName, CrowdfundParameters parameters);

	event FundsAdded(string groupName, address contributor, uint256 contribution);

	event CommissionSet(uint256 commission);

	event Cancelled(string groupName);

	event Processed(string groupName, address indexed groupAddress);

	/// -----------------------------------------------------------------------
	/// Errors
	/// -----------------------------------------------------------------------

	error MissingCrowdfund();

	error MemberLimitReached();

	error InsufficientFunds();

	error FounderBonusExceeded();

	error OpenFund();

	/// -----------------------------------------------------------------------
	/// Crowdfund Storage
	/// -----------------------------------------------------------------------

	struct CrowdfundParameters {
		address targetContract; // When the crowdfund transaction will take place (eg. a marketplace)
		address assetContract; // The asset contract the crowdfund will buy (eg. an ERC721 collection)
		uint32 deadline; // The deadline for the crowdfund
		uint256 tokenId; // The token ID the crowdfund will buy
		uint256 founderBonus; // An optional bonus the founder can set to incentivize early contributions
		string groupName; // The name of the group which will be deployed to manage the groups asset
		string symbol; // The symbol of the group which will be deployed to manage the groups asset
		bytes payload; // The payload to be sent to the target contract when the crowdfund is processed
	}

	struct Crowdfund {
		address[] contributors;
		mapping(address => uint256) contributions;
		CrowdfundParameters parameters;
	}

	address public forumFactory;
	address public executionManager;

	uint256 public commission = 200; // Basis points of 10000 => 2%

	mapping(bytes32 => Crowdfund) public crowdfunds;

	/// -----------------------------------------------------------------------
	/// Constructor
	/// -----------------------------------------------------------------------

	constructor(
		address deployer,
		address forumFactory_,
		address executionManager_
	) Owned(deployer) {
		forumFactory = forumFactory_;

		executionManager = executionManager_;
	}

	/// ----------------------------------------------------------------------------------------
	///							Owner Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Sets commission %
	 * @param _commission for crowdfunds as basis points on 1000 (e.g. 250 = 2.5%)
	 */
	function setCommission(uint256 _commission) external onlyOwner {
		commission = _commission;
		emit CommissionSet(_commission);
	}

	/// ----------------------------------------------------------------------------------------
	///							Crowdfund Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Initiate a crowdfund to buy an asset
	 * @param parameters the parameters struct for the crowdfund
	 */
	function initiateCrowdfund(
		CrowdfundParameters calldata parameters
	) public payable virtual nonReentrant {
		// Using the bytes32 hash of the name as mapping key saves ~250 gas instead of string
		bytes32 groupNameHash = keccak256(abi.encode(parameters.groupName));

		if (crowdfunds[groupNameHash].parameters.deadline != 0) revert OpenFund();

		// Founder bonus capped at 5%
		if (parameters.founderBonus > 500) revert FounderBonusExceeded();

		// No gas saving to use crowdfund({}) format, and since we need to push to the array, we assign each element individually.
		crowdfunds[groupNameHash].parameters = parameters;
		crowdfunds[groupNameHash].contributors.push(msg.sender);
		crowdfunds[groupNameHash].contributions[msg.sender] = msg.value;

		emit NewCrowdfund(parameters.groupName, parameters);
	}

	/**
	 * @notice Submit a crowdfund contribution
	 * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
	 */
	function submitContribution(bytes32 groupNameHash) public payable virtual nonReentrant {
		Crowdfund storage fund = crowdfunds[groupNameHash];

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
			payable(fund.contributors[i]).call{value: fund.contributions[msg.sender]}('');

			// Delete the contribution in the mapping
			delete fund.contributions[fund.contributors[i]];

			// Members can only be 12
			unchecked {
				++i;
			}
		}

		emit Cancelled(fund.parameters.groupName);

		delete crowdfunds[groupNameHash];
	}

	/**
	 * @notice Process a crowdfund and deploy a Forum group
	 * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
	 */
	function processCrowdfund(bytes32 groupNameHash) public virtual nonReentrant {
		Crowdfund storage fund = crowdfunds[groupNameHash];

		if (fund.parameters.deadline == 0) revert MissingCrowdfund();

		// CustomExtension of address(this) allows this contract to mint each member shares
		address[] memory customExtensions = new address[](1);
		customExtensions[0] = address(this);

		// Deploy the Forum group to hold the NFT as a group
		// Default settings of 3 days vote period, 100 member limit, 80% member & token vote thresholds
		IForumGroup forumGroup = IForumGroupFactory(forumFactory).deployGroup(
			fund.parameters.groupName,
			fund.parameters.symbol,
			[uint32(3 days), uint32(100), uint32(80), uint32(80)],
			fund.contributors,
			customExtensions
		);

		// Decode the executed payload based on the target contract,
		// and generate a transferPayload to send the asset to the Forum group after it is purchased
		(uint256 assetPrice, bytes memory transferPayload) = ICrowdfundExecutionManager(
			executionManager
		).manageExecution(
				address(this),
				fund.parameters.targetContract,
				fund.parameters.assetContract,
				address(forumGroup),
				fund.parameters.tokenId,
				fund.parameters.payload
			);

		// Total raised and expected commission
		uint256 raised;
		uint256 expectedCommmission = (assetPrice * commission) / 10000;

		// Unchecked as price or raised amount will not exceed max int
		unchecked {
			// Calculate the total raised and mint group shares (id = 1) to each contributor
			for (uint256 i; i < fund.contributors.length; ) {
				raised += fund.contributions[fund.contributors[i]];
				forumGroup.mintShares(
					fund.contributors[i],
					1,
					fund.contributions[fund.contributors[i]]
				);
				++i;
			}
			if (raised == 0 || raised < expectedCommmission) revert InsufficientFunds();
		}

		// Send the founder bonus
		forumGroup.mintShares(
			fund.contributors[0],
			1,
			(raised * fund.parameters.founderBonus) / 10000
		);

		// Execute the tx with payload
		(bool success, bytes memory result) = (fund.parameters.targetContract).call{
			value: assetPrice
		}(fund.parameters.payload);

		// If the tx fails, revert
		if (!success) revert(string(result));

		// Send the asset to the Forum group
		(bool success2, ) = (fund.parameters.assetContract).call(transferPayload);

		// If the transfer fails, revert
		if (!success2) revert(string(result));

		// Excess funds to pay commission and be transferred to group
		uint256 excessFunds = raised - assetPrice;
		uint256 finalCommission = (raised * commission) / 10000;

		// Revert if insufficent funds to pay commission, otherwise send commission to Forum.
		if (excessFunds < expectedCommmission) revert InsufficientFunds();
		executionManager.call{value: finalCommission}(new bytes(0));

		// Update the value of the excess funds after commission has been taken
		excessFunds -= finalCommission;

		// If there are leftover funds, transfer them to the forum group
		if (excessFunds > 0) {
			address(forumGroup).call{value: excessFunds}('');
		}

		emit Processed(fund.parameters.groupName, address(forumGroup));

		delete crowdfunds[groupNameHash];
	}

	/**
	 * @notice Get the details of contributions from a crowdfund
	 * @param groupNameHash hash of the group name
	 */
	function getCrowdfundContributors(
		bytes32 groupNameHash
	) public view returns (address[] memory contributors, uint256[] memory contributions) {
		Crowdfund storage fund = crowdfunds[groupNameHash];

		contributions = new uint256[](crowdfunds[groupNameHash].contributors.length);
		for (uint256 i; i < fund.contributors.length; ) {
			contributions[i] = fund.contributions[fund.contributors[i]];
			unchecked {
				++i;
			}
		}
		(contributors, contributions) = (fund.contributors, contributions);
	}
}
