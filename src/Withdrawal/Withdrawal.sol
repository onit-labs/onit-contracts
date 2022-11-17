// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.4;

import "../libraries/SafeTransferLib.sol";
import "../interfaces/IERC20.sol"; // consider minimla version
import "../utils/ReentrancyGuard.sol";

/// @notice Withdrawal contract that transfers registered tokens from Forum group in proportion to burnt DAO tokens.
contract ForumWithdrawal is ReentrancyGuard {
    using SafeTransferLib for address;

    /// ----------------------------------------------------------------------------------------
    /// Errors and Events
    /// ----------------------------------------------------------------------------------------

    event ExtensionSet(
        address indexed dao, address[] tokens, uint256 indexed redemptionStart
    );

    event ExtensionCalled(
        address indexed dao,
        address indexed member,
        uint256 indexed amountBurned
    );

    event TokensAdded(address indexed dao, address[] tokens);

    event TokensRemoved(address indexed dao, uint256[] tokenIndex);

    error NullTokens();

    error NotStarted();

    /// ----------------------------------------------------------------------------------------
    /// Withdrawl Storage
    /// ----------------------------------------------------------------------------------------

    mapping(address => address[]) public withdrawables;

    mapping(address => uint256) public redemptionStarts;

    function getRedeemables(address dao)
        public
        view
        virtual
        returns (address[] memory tokens)
    {
        tokens = withdrawables[dao];
    }

    /// ----------------------------------------------------------------------------------------
    /// Withdrawal Logic
    /// ----------------------------------------------------------------------------------------

    function submitWithdrawlProposal() // IKaliDAOtribute dao,
        // IKaliDAOtribute.ProposalType proposalType,
        // string memory description,
        // address[] calldata accounts,
        // uint256[] calldata amounts,
        // bytes[] calldata payloads,
        // bool nft,
        // address asset,
        // uint256 value
     public payable virtual nonReentrant {
        // basic safety checks
        // token requested type checks
        // create proposal
        // store details here somhow for processing
    }

    /**
     * @notice Set the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
     * @param extensionData to set the extension
     */
    function setExtension(bytes calldata extensionData)
        public
        virtual
        nonReentrant
    {
        (address[] memory tokens, uint256 redemptionStart) =
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

        redemptionStarts[msg.sender] = redemptionStart;

        emit ExtensionSet(msg.sender, tokens, redemptionStart);
    }

    function callExtension(address account, uint256 amount, bytes calldata)
        public
        virtual
        nonReentrant
        returns (bool mint, uint256 amountOut)
    {
        if (block.timestamp < redemptionStarts[msg.sender]) revert NotStarted();

        // extract assets from calldata

        // transfer assets to member

        // burn tokens

        // consider burn of membership

        // ! confirm calculations here
        // ! check against some type of unit value?
        for (uint256 i; i < withdrawables[msg.sender].length;) {
            // calculate fair share of given token for redemption
            uint256 amountToRedeem = amount
                * IERC20(withdrawables[msg.sender][i]).balanceOf(msg.sender)
                / IERC20(msg.sender).totalSupply();

            // `transferFrom` DAO to redeemer
            if (amountToRedeem != 0) {
                address(withdrawables[msg.sender][i])._safeTransferFrom(
                    msg.sender, account, amountToRedeem
                );
            }

            // cannot realistically overflow on human timescales
            unchecked {
                i++;
            }
        }

        // Values to conform to extension interface and burn group tokens of this amount
        (mint, amountOut) = (false, amount);

        emit ExtensionCalled(msg.sender, account, amount);
    }

    function addTokens(address[] calldata tokens) public virtual nonReentrant {
        // cannot realistically overflow on human timescales
        unchecked {
            for (uint256 i; i < tokens.length; i++) {
                withdrawables[msg.sender].push(tokens[i]);
            }
        }

        emit TokensAdded(msg.sender, tokens);
    }

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
}
