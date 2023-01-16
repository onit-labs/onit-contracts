// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {SafeTransferLib} from '@libraries/SafeTransferLib.sol';

import {IERC1155} from '@openzeppelin/contracts/interfaces/IERC1155.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';

import {IForumGroup, IForumGroupTypes} from '@interfaces/IForumGroup.sol';
import {IWithdrawalTransferManager} from '@interfaces/IWithdrawalTransferManager.sol';

import {ReentrancyGuard} from '@utils/ReentrancyGuard.sol';

/// @notice Withdrawal contract that transfers registered tokens from Forum group in proportion to burnt DAO tokens.
contract ForumWithdrawal is ReentrancyGuard {
	using SafeTransferLib for address;

	/// ----------------------------------------------------------------------------------------
	/// Events
	/// ----------------------------------------------------------------------------------------

	event ExtensionSet(address indexed group, address[] tokens, uint256 indexed withdrawalStart);

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

	event CustomWithdrawalProcessed(
		address indexed withdrawer,
		address indexed group,
		uint256 amount
	);

	event TokensAdded(address indexed group, address[] tokens);

	event TokensRemoved(address indexed group, uint256[] tokenIndex);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error NullTokens();

	error IncorrectAmount();

	error NotStarted();

	error NotMember();

	error NoArrayParity();

	/// ----------------------------------------------------------------------------------------
	/// Withdrawl Storage
	/// ----------------------------------------------------------------------------------------

	struct CustomWithdrawal {
		address[] tokens;
		uint256[] amountOrId;
		uint256 amountToBurn;
	}

	IWithdrawalTransferManager public withdrawalTransferManager;

	// Pre-set assets which can be redeemed at any point by members
	mapping(address => address[]) public withdrawables;
	// Start time for withdrawals
	mapping(address => uint256) public withdrawalStarts;
	// Custom withdrawals proposed to a group by a member (group, member, CustomWithdrawal)
	mapping(address => mapping(address => CustomWithdrawal)) private customWithdrawals;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(address _withdrawalTransferManager) {
		withdrawalTransferManager = IWithdrawalTransferManager(_withdrawalTransferManager);
	}

	/// ----------------------------------------------------------------------------------------
	/// Withdrawal Logic
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Set the withdrawl extension for a DAO. This sets the available redeemable tokens which can be claimed at any time by a member.
	 * @param extensionData to set the extension
	 */
	function setExtension(bytes calldata extensionData) public virtual nonReentrant {
		(address[] memory tokens, uint256 withdrawalStart) = abi.decode(
			extensionData,
			(address[], uint256)
		);

		if (tokens.length == 0) revert NullTokens();

		// If withdrawables are already set, this call will be interpreted as reset
		if (withdrawables[msg.sender].length != 0) delete withdrawables[msg.sender];

		// Cannot realistically overflow on human timescales
		unchecked {
			for (uint256 i; i < tokens.length; ) {
				withdrawables[msg.sender].push(tokens[i]);

				++i;
			}
		}

		withdrawalStarts[msg.sender] = withdrawalStart;

		emit ExtensionSet(msg.sender, tokens, withdrawalStart);
	}

	/**
	 * @notice Withdraw tokens from a DAO. This will withdraw tokens in proportion to the amount of DAO tokens burned.
	 * @param withdrawer address to withdraw tokens to
	 * @param amount amount of DAO tokens burned - basis points, 10,000 = 100%
	 * @dev bytes unused but conforms with standard interface for extension
	 */
	function callExtension(
		address withdrawer,
		uint256 amount,
		bytes calldata
	) public virtual nonReentrant returns (bool mint, uint256 amountOut) {
		if (block.timestamp < withdrawalStarts[msg.sender]) revert NotStarted();

		if (amount > 10000) revert IncorrectAmount();

		// Token amount to be withdrawn, given the 'amount' (%) in basis points of 10000
		uint256 tokenAmount = (amount * IForumGroup(msg.sender).balanceOf(withdrawer, 1)) / 10000;

		for (uint256 i; i < withdrawables[msg.sender].length; ) {
			// Calculate fair share of given token for withdrawal
			uint256 amountToRedeem = (tokenAmount *
				IERC20(withdrawables[msg.sender][i]).balanceOf(msg.sender)) /
				IERC20(msg.sender).totalSupply();

			// `transferFrom` DAO to redeemer
			if (amountToRedeem != 0) {
				address(withdrawables[msg.sender][i])._safeTransferFrom(
					msg.sender,
					withdrawer,
					amountToRedeem
				);
			}

			// cannot realistically overflow on human timescales
			unchecked {
				i++;
			}
		}

		// Values to conform to extension interface and burn group tokens of this amount
		(mint, amountOut) = (false, tokenAmount);

		emit ExtensionCalled(msg.sender, withdrawer, tokenAmount);
	}

	/**
	 * @notice Submits a proposal to the group to withdraw an item not already set in the extension.
	 * @param group to withdraw from
	 * @param accounts contract address of assets to withdraw
	 * @param amounts to withdraw if needed
	 */
	function submitWithdrawlProposal(
		IForumGroup group,
		address[] calldata accounts,
		uint256[] calldata amounts,
		uint256 amount
	) public payable virtual nonReentrant {
		// Sender must be group member
		if (group.balanceOf(msg.sender, 0) == 0) revert NotMember();

		// Array lenghts must match
		if (accounts.length != amounts.length) revert NoArrayParity();

		// Set allowance for DAO to burn members tokens
		customWithdrawals[address(group)][msg.sender].amountToBurn += amount;

		// +1 to include the call to processWithdrawalProposal function on this contract
		uint256 adjustedArrayLength = accounts.length + 1;

		// Accouts to be sent to the group proposal
		address[] memory proposalAccounts = new address[](adjustedArrayLength);

		for (uint256 i; i < accounts.length; ) {
			proposalAccounts[i] = accounts[i];

			// Will not overflow for length of assets
			unchecked {
				++i;
			}
		}

		// Add this contract to the end of the array
		proposalAccounts[adjustedArrayLength - 1] = address(this);

		// Create payloads based on input tokens and amounts
		bytes[] memory proposalPayloads = new bytes[](adjustedArrayLength);

		// Loop the input accounts and create payloads
		for (uint256 i; i < accounts.length; ) {
			// Build the approval for the group to allow the asset to be transferred
			proposalPayloads[i] = withdrawalTransferManager.buildApprovalPayloads(
				accounts[i],
				amounts[i]
			);

			// Store the account and amountOrId which can be withdrawn from it
			// This ensures that only this member from this group can withdraw the assets the group have approved
			customWithdrawals[address(group)][msg.sender].tokens.push(accounts[i]);
			customWithdrawals[address(group)][msg.sender].amountOrId.push(amounts[i]);

			// Will not overflow for length of assets
			unchecked {
				++i;
			}
		}

		// Build the payload to call processWithdrawalProposal on this contract and put it as the last payload
		// This will process the withdrawal as soon as the vote is passed
		proposalPayloads[adjustedArrayLength - 1] = abi.encodeWithSignature(
			'processWithdrawalProposal(address)',
			msg.sender
		);

		// Submit proposal to DAO - amounts is set to an new empty array as it is not needed (amounts are set in the payloads)
		uint256 proposal = group.propose(
			IForumGroupTypes.ProposalType.CALL,
			proposalAccounts,
			new uint256[](adjustedArrayLength),
			proposalPayloads
		);

		emit CustomWithdrawalAdded(msg.sender, address(group), proposal, amount);
	}

	/**
	 * @notice processWithdrawalProposal processes a proposal to withdraw an item not already set in the extension.
	 * @param withdrawer to take assets and burn tokens for
	 */
	function processWithdrawalProposal(address withdrawer) public virtual nonReentrant {
		CustomWithdrawal memory withdrawal = customWithdrawals[msg.sender][withdrawer];

		// Burn group tokens (id=1)
		IForumGroup(msg.sender).burnShares(withdrawer, 1, withdrawal.amountToBurn);

		for (uint256 i; i < withdrawal.tokens.length; ) {
			// For each token, transfer the amountOrId to the withdrawer
			withdrawalTransferManager.executeTransferPayloads(
				withdrawal.tokens[i],
				msg.sender,
				withdrawer,
				withdrawal.amountOrId[i]
			);

			// Will not overflow for length of assets
			unchecked {
				++i;
			}
		}

		emit CustomWithdrawalProcessed(msg.sender, msg.sender, withdrawal.amountToBurn);

		// Delete the withdrawal
		delete customWithdrawals[msg.sender][withdrawer];
	}

	/**
	 * @notice lets a member remove their custom withdrawal request
	 * @param group to remove allowance from
	 */
	function removeAllowance(address group) public virtual nonReentrant {
		delete customWithdrawals[group][msg.sender];
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
	function removeTokens(uint256[] calldata tokenIndex) public virtual nonReentrant {
		for (uint256 i; i < tokenIndex.length; i++) {
			// move last token to replace indexed spot and pop array to remove last token
			withdrawables[msg.sender][tokenIndex[i]] = withdrawables[msg.sender][
				withdrawables[msg.sender].length - 1
			];

			withdrawables[msg.sender].pop();
		}

		emit TokensRemoved(msg.sender, tokenIndex);
	}

	function getWithdrawables(address group) public view virtual returns (address[] memory tokens) {
		tokens = withdrawables[group];
	}

	/**
	 * @notice Returns the custom withdrawal for a member of a group
	 * @param group to get custom withdrawal from
	 * @param member to get custom withdrawal for
	 */
	function getCustomWithdrawals(
		address group,
		address member
	)
		public
		view
		virtual
		returns (address[] memory tokens, uint256[] memory amounts, uint256 amountToBurn)
	{
		tokens = customWithdrawals[group][member].tokens;
		amounts = customWithdrawals[group][member].amountOrId;
		amountToBurn = customWithdrawals[group][member].amountToBurn;
	}
}
