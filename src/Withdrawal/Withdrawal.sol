// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import "../libraries/SafeTransferLib.sol";

import "../interfaces/IERC20.sol"; // consider minimal version
import "../interfaces/IForumGroup.sol";

import "../utils/ReentrancyGuard.sol";

import "forge-std/console2.sol";

/// @notice Withdrawal contract that transfers registered tokens from Forum group in proportion to burnt DAO tokens.
contract ForumWithdrawal is ReentrancyGuard {
    using SafeTransferLib for address;

    /// ----------------------------------------------------------------------------------------
    /// Errors and Events
    /// ----------------------------------------------------------------------------------------

    event ExtensionSet(
        address indexed group, address[] tokens, uint256 indexed withdrawalStart
    );

    event ExtensionCalled(
        address indexed group,
        address indexed member,
        uint256 indexed amountBurned
    );

    event CustomWithdrawalAdded(
        address indexed withdrawer,
        address indexed group,
        uint256 indexed proposal,
        uint256 amount
    );

    event TokensAdded(address indexed group, address[] tokens);

    event TokensRemoved(address indexed group, uint256[] tokenIndex);

    error NullTokens();

    error NotStarted();

    error NotMember();

    error IncorrectAmount();

    /// ----------------------------------------------------------------------------------------
    /// Withdrawl Storage
    /// ----------------------------------------------------------------------------------------

    // Pre-set assets which can be redeemed at any point by members
    mapping(address => address[]) public withdrawables;
    // Allowance the group can burn for a member in a custom withdrawal (group, member, amount))
    mapping(address => mapping(address => uint256)) public allowances;
    // Start time for withdrawals
    mapping(address => uint256) public withdrawalStarts;

    /// ----------------------------------------------------------------------------------------
    /// Withdrawal Logic
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Set the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
     * @param extensionData to set the extension
     */
    function setExtension(bytes calldata extensionData)
        public
        virtual
        nonReentrant
    {
        (address[] memory tokens, uint256 withdrawalStart) =
            abi.decode(extensionData, (address[], uint256));

        if (tokens.length == 0) revert NullTokens();

        // if withdrawables are already set, this call will be interpreted as reset
        if (withdrawables[msg.sender].length != 0)
        delete withdrawables[msg.sender];
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                withdrawables[msg.sender].push(tokens[i]);
            }
        }

        withdrawalStarts[msg.sender] = withdrawalStart;

        emit ExtensionSet(msg.sender, tokens, withdrawalStart);
    }

    /**
     * @notice Withdraw tokens from a DAO. This will withdraw tokens in proportion to the amount of DAO tokens burned.
     * @param withdrawer address to withdraw tokens to
     * @param amount amount of DAO tokens burned
     * @dev  bytes unused but conforms with standard interface for extension
     */
    function callExtension(address withdrawer, uint256 amount, bytes calldata)
        public
        virtual
        nonReentrant
        returns (bool mint, uint256 amountOut)
    {
        if (block.timestamp < withdrawalStarts[msg.sender]) revert NotStarted();

        for (uint256 i; i < withdrawables[msg.sender].length;) {
            // calculate fair share of given token for withdrawal
            uint256 amountToRedeem = amount
                * IERC20(withdrawables[msg.sender][i]).balanceOf(msg.sender)
                / IERC20(msg.sender).totalSupply();

            // `transferFrom` DAO to redeemer
            if (amountToRedeem != 0) {
                address(withdrawables[msg.sender][i])._safeTransferFrom(
                    msg.sender, withdrawer, amountToRedeem
                );
            }

            // cannot realistically overflow on human timescales
            unchecked {
                i++;
            }
        }

        // Values to conform to extension interface and burn group tokens of this amount
        (mint, amountOut) = (false, amount);

        emit ExtensionCalled(msg.sender, withdrawer, amount);
    }

    /**
     * @notice Submits a proposal to the group to withdraw an item not already set in the extension.
     * @param group to withdraw from
     * @param accounts contract address of assets to withdraw
     * @param amounts to withdraw if needed
     * @param payloads to withdraw ie. transfer the group asset to the member
     */
    function submitWithdrawlProposal(
        IForumGroup group,
        address[] calldata accounts,
        uint256[] calldata amounts,
        bytes[] calldata payloads,
        uint256 amount
    )
        public
        payable
        virtual
        nonReentrant
    {
        // Sender must be group member
        if (group.balanceOf(msg.sender, 0) == 0) revert NotMember();

        // Set allowance for DAO to burn members tokens
        allowances[address(group)][msg.sender] += amount;

        // Create payload based on input tokens and amounts

        // Submit proposal to DAO
        uint256 proposal = group.propose(
            IForumGroupTypes.ProposalType.CALL, accounts, amounts, payloads
        );

        emit CustomWithdrawalAdded(msg.sender, address(group), proposal, amount);
    }

    /**
     * @notice processWithdrawalProposal processes a proposal to withdraw an item not already set in the extension.
     * @param withdrawer to take burn tokens for
     * @param amount to withdraw
     */
    function processWithdrawalProposal(address withdrawer, uint256 amount)
        public
        virtual
        nonReentrant
    {
        // ! NEED TO check withdrawer has agreed to this so tokens cant just be burnt

        // Sender must have allowance to withdraw
        if (allowances[msg.sender][withdrawer] < amount) revert IncorrectAmount();

        // Burn allowance
        allowances[msg.sender][withdrawer] -= amount;

        // Burn group tokens
        IForumGroup(msg.sender).burnShares(withdrawer, 1, amount);
    }

    /**
     * @notice lets a member remove their burn allowance
     * @param group to remove allowance from
     * @param amount to remove
     */
    function removeAllowance(address group, uint256 amount)
        public
        virtual
        nonReentrant
    {
        allowances[group][msg.sender] -= amount;
    }

    /**
     * @notice Add tokens to the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
     * @param tokens to add to the withdrawl extension
     */
    function addTokens(address[] calldata tokens) public virtual nonReentrant {
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                withdrawables[msg.sender].push(tokens[i]);
            }
        }

        emit TokensAdded(msg.sender, tokens);
    }

    /**
     * @notice Remove tokens from the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
     * @param tokenIndex to remove from the withdrawl extension
     */
    function removeTokens(uint256[] calldata tokenIndex)
        public
        virtual
        nonReentrant
    {
        for (uint256 i; i < tokenIndex.length; i++) {
            // move last token to replace indexed spot and pop array to remove last token
            withdrawables[msg.sender][tokenIndex[i]] =
                withdrawables[msg.sender][withdrawables[msg.sender].length - 1];

            withdrawables[msg.sender].pop();
        }

        emit TokensRemoved(msg.sender, tokenIndex);
    }

    function getWithdrawables(address group)
        public
        view
        virtual
        returns (address[] memory tokens)
    {
        tokens = withdrawables[group];
    }
}
