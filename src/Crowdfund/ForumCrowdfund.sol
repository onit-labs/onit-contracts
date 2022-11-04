// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {SafeTransferLib} from "../libraries/SafeTransferLib.sol";

import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";

import {IForumGroup} from "../interfaces/IForumGroup.sol";

/**
 * @title Forum Crowdfund
 * @notice Lets people pool funds to purchase an item as a group, deploying a Forum group for management
 */
contract ForumCrowdfund is ReentrancyGuard {
    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event NewCrowdfund(
        bytes32 indexed groupName,
        bytes32 symbol,
        address proposer,
        uint256 targetPrice,
        uint32 deadline
    );

    event FundsAdded(
        bytes32 indexed groupName,
        address contributor,
        uint256 contribution
    );

    event Cancelled(bytes32 indexed groupName);

    event Processed(bytes32 indexed groupName, address indexed groupAddress);

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
    /// Crowdfund Storage
    /// -----------------------------------------------------------------------

    struct Crowdfund {
        address targetContract;
        address[] contributors;
        uint256[] contributions;
        uint256 targetPrice;
        uint32 deadline;
        bytes32 groupName;
        bytes32 symbol;
        bytes payload;
    }

    uint256 private constant MEMBERSHIP = 0;
    uint256 private constant TOKEN = 1;

    // todo maybe improve key
    mapping(bytes32 => Crowdfund) private crowdfunds;

    mapping(address => mapping(address => bool)) public contributionTracker;

    /// -----------------------------------------------------------------------
    /// Fundraise Logic
    /// -----------------------------------------------------------------------

    // todo consider commission and fit into target value
    /**
     * @notice Initiate a crowdfund to buy an asset
     * @param creator of the fund
     * @param targetContract where the asset is to be purchased
     * @param targetPrice of the asset
     * @param deadline until when the crowdfund is valid, cancelled if not met
     * @param groupName of the group to be deployed
     * @param symbol of the group to be deployed
     * @param payload calldata for the target asset
     */
    function initiateCrowdfund(
        address creator,
        address targetContract,
        uint256 targetPrice,
        uint32 deadline,
        bytes32 groupName,
        bytes32 symbol,
        bytes calldata payload
    ) public payable virtual nonReentrant {
        // maybe check the amount?
        // maybe check sender?
        if (crowdfunds[groupName].deadline != 0) revert OpenFund();

        // No gas saving to use Fund({}) format, and since we need to push to the arry, we assign each element individually.
        crowdfunds[groupName].contributors.push(creator);
        crowdfunds[groupName].contributions.push(msg.value);
        crowdfunds[groupName].targetPrice = targetPrice;
        crowdfunds[groupName].targetContract = targetContract;
        crowdfunds[groupName].deadline = deadline;
        crowdfunds[groupName].groupName = groupName;
        crowdfunds[groupName].symbol = symbol;
        crowdfunds[groupName].payload = payload;

        // crowdfunds[groupName] = Crowdfund({
        //     contributors: [],
        //     contributions: [],
        //     targetPrice: targetPrice,
        //     targetContract: targetContract,
        //     deadline: deadline,
        //     groupName: groupName,
        //     symbol: symbol,
        //     payload: payload
        // });

        emit NewCrowdfund(groupName, symbol, creator, targetPrice, deadline);
    }

    // ! need to prevent same address from being added twice - sum their contribution somehow? or just limit to one contribution per address
    /**
     * @notice Submit a crowdfund contribution
     * @param groupName name of group
     */
    function submitContribution(bytes32 groupName)
        public
        payable
        virtual
        nonReentrant
    {
        // ! NEED TO IMPLEMENT THIS
        // // Can only contribute once per fund
        // if (contributionTracker[groupAddress][msg.sender])
        //     revert IncorrectContribution();

        // ! consider a check on contributions and target price
        // if (msg.value != funds[groupAddress].individualContribution)
        //     revert IncorrectContribution();

        if (crowdfunds[groupName].deadline == 0) revert FundraiseMissing();

        crowdfunds[groupName].contributors.push(msg.sender);
        crowdfunds[groupName].contributions.push(msg.value);

        emit FundsAdded(groupName, msg.sender, msg.value);
    }

    // /**
    //  * @notice Cancel a fundraise and return funds to contributors
    //  * @param groupAddress Address of group
    //  */
    // function cancelFundRound(address groupAddress) public virtual nonReentrant {
    //     if (IForumGroup(groupAddress).balanceOf(msg.sender, MEMBERSHIP) == 0)
    //         revert NotMember();

    //     Fund storage fund = funds[groupAddress];

    //     // Only groupAddress or proposer can cancel the fundraise.
    //     if (!(msg.sender == groupAddress || msg.sender == fund.contributors[0]))
    //         revert NotProposer();

    //     // Return funds from escrow
    //     for (uint256 i; i < fund.contributors.length; ) {
    //         payable(fund.contributors[i]).transfer(fund.individualContribution);
    //         contributionTracker[groupAddress][fund.contributors[i]] = false;

    //         // Members can only be 12
    //         unchecked {
    //             ++i;
    //         }
    //     }

    //     delete funds[groupAddress];

    //     emit FundRoundCancelled(groupAddress);
    // }

    // /**
    //  * @notice Process the fundraise, sending AVAX to group and minting tokens to contributors
    //  * @param groupAddress Address of group
    //  */
    // function processFundRound(address groupAddress)
    //     public
    //     virtual
    //     nonReentrant
    // {
    //     Fund memory fund = funds[groupAddress];

    //     if (funds[groupAddress].individualContribution == 0)
    //         revert FundraiseMissing();

    //     uint256 memberCount = fund.contributors.length;

    //     // We adjust the number of shares distributed based on the unitValue of group tokens
    //     // This ensures that members get a fair number of tokens given the value of the treasury at any time
    //     uint256 adjustedContribution = (fund.individualContribution *
    //         fund.valueDenominator) / fund.valueNumerator;

    //     if (memberCount != IForumGroup(groupAddress).memberCount())
    //         revert MembersMissing();

    //     groupAddress._safeTransferETH(
    //         fund.individualContribution * memberCount
    //     );

    //     for (uint256 i; i < memberCount; ) {
    //         // Mint member an share of tokens equal to their contribution and reset their status in the tracker
    //         IForumGroup(groupAddress).mintShares(
    //             fund.contributors[i],
    //             TOKEN,
    //             adjustedContribution
    //         );
    //         contributionTracker[groupAddress][fund.contributors[i]] = false;

    //         // Members can only be 12
    //         unchecked {
    //             ++i;
    //         }
    //     }

    //     delete funds[groupAddress];

    //     emit FundRoundReleased(
    //         groupAddress,
    //         fund.contributors,
    //         fund.individualContribution
    //     );
    // }

    /**
     * @notice Get the details of a crowdfund
     * @param groupName name of the group
     */
    function getCrowdfund(bytes32 groupName)
        public
        view
        returns (Crowdfund memory crowdfundDetails)
    {
        return crowdfunds[groupName];
    }
}
