// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import "hardhat/console.sol";
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

    event NewCrowdfund(string indexed groupName);

    event FundsAdded(
        string indexed groupName,
        address contributor,
        uint256 contribution
    );

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
        uint256[] contributions;
        CrowdfundParameters parameters;
    }

    mapping(bytes32 => Crowdfund) private crowdfunds;

    mapping(address => mapping(address => bool)) public contributionTracker;

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
        if (crowdfunds[groupNameHash].parameters.deadline != 0)
            revert OpenFund();

        // No gas saving to use Fund({}) format, and since we need to push to the arry, we assign each element individually.
        crowdfunds[groupNameHash].contributors.push(msg.sender);
        crowdfunds[groupNameHash].contributions.push(msg.value);
        crowdfunds[groupNameHash].parameters = parameters;

        emit NewCrowdfund(parameters.groupName);
    }

    // ! need to prevent same address from being added twice - sum their contribution somehow? or just limit to one contribution per address
    /**
     * @notice Submit a crowdfund contribution
     * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
     */
    function submitContribution(bytes32 groupNameHash)
        public
        payable
        virtual
        nonReentrant
    {
        // ! consider a check on contributions and target price
        // if (msg.value != funds[groupAddress].individualContribution)
        //     revert IncorrectContribution();

        // ! consider member limit
        if (crowdfunds[groupNameHash].contributors.length == 12)
            revert MemberLimitReached();

        if (crowdfunds[groupNameHash].parameters.deadline == 0)
            revert MissingCrowdfund();

        crowdfunds[groupNameHash].contributors.push(msg.sender);
        crowdfunds[groupNameHash].contributions.push(msg.value);

        emit FundsAdded(
            crowdfunds[groupNameHash].parameters.groupName,
            msg.sender,
            msg.value
        );
    }

    /**
     * @notice Cancel a crowdfund and return funds to contributors
     * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
     */
    function cancelCrowdfund(bytes32 groupNameHash)
        public
        virtual
        nonReentrant
    {
        Crowdfund memory fund = crowdfunds[groupNameHash];

        if (fund.parameters.deadline > block.timestamp) revert OpenFund();

        // Return funds from escrow
        for (uint256 i; i < fund.contributors.length; ) {
            console.logAddress(fund.contributors[i]);
            console.logUint(fund.contributions[i]);
            payable(fund.contributors[i]).transfer(fund.contributions[i]);

            // Members can only be 12
            unchecked {
                ++i;
            }
        }

        delete crowdfunds[groupNameHash];

        emit Cancelled(fund.parameters.groupName);
    }

    //     /**
    //      * @notice Process a crowdfund and deploy a Forum group
    //      * @param groupNameHash bytes32 hashed name of group (saves gas compared to string)
    //      */ // todo consider a check on contributions and target price
    //     function processCrowdfund(bytes32 groupNameHash)
    //         public
    //         virtual
    //         nonReentrant
    //     {
    //         Crowdfund memory fund = crowdfunds[groupNameHash];

    // // todo consider block on deadline
    //         // if (fund.parameters.deadline > block.timestamp) revert OpenFund();

    //         // Deploy the Forum group
    //         address groupAddress = IForumGroup(fund.parameters.targetContract)
    //             .deployGroup{value: fund.parameters.targetPrice}(
    //                 fund.parameters.groupName,
    //                 fund.parameters.symbol,
    //                 fund.parameters.payload
    //             );

    //         // Return funds from escrow
    //         for (uint256 i; i < fund.contributors.length; ) {
    //             console.logAddress(fund.contributors[i]);
    //             console.logUint(fund.contributions[i]);
    //             payable(fund.contributors[i]).transfer(fund.contributions[i]);

    //             // Members can only be 12
    //             unchecked {
    //                 ++i;
    //             }
    //         }

    //         delete crowdfunds[groupNameHash];

    //         emit Processed(fund.parameters.groupName, groupAddress);
    //     }

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
    //         revert MemberLimitReached();

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
     * @param groupNameHash hash of the group name
     */
    function getCrowdfund(bytes32 groupNameHash)
        public
        view
        returns (Crowdfund memory crowdfundDetails)
    {
        return crowdfunds[groupNameHash];
    }
}
