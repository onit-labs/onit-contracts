// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import '@gnosis.pm/zodiac/contracts/core/Module.sol';

import {ForumGovernance, EnumerableSet} from './ForumSafeGovernance.sol';

// TODO consider need for NFTreceiver - does the module need to receive?
import {NFTreceiver} from '../utils/NFTreceiver.sol';
import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';

import {IForumGroupTypes} from '../interfaces/IForumGroupTypes.sol';
import {IForumGroupExtension} from '../interfaces/IForumGroupExtension.sol';
import {IPfpStaker} from '../interfaces/IPfpStaker.sol';

/**
 * @title ForumSafeModule
 * @notice Forum investment group governance extension for Gnosis Safe
 * @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)
 */
contract ForumSafeModule is
	Module,
	IForumGroupTypes,
	ForumGovernance,
	ReentrancyGuard,
	NFTreceiver
{
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event NewProposal(
		address indexed proposer,
		uint256 indexed proposal,
		ProposalType indexed proposalType,
		address[] accounts,
		uint256[] amounts,
		bytes[] payloads
	);

	event ProposalProcessed(
		ProposalType indexed proposalType,
		uint256 indexed proposal,
		bool indexed didProposalPass
	);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error AlreadyInitialized();

	error MemberLimitExceeded();

	error PeriodBounds();

	error VoteThresholdBounds();

	error TypeBounds();

	error NoArrayParity();

	error NotCurrentProposal();

	error NotExtension();

	error PFPFailed();

	error SignatureError();

	error CallError();

	/// ----------------------------------------------------------------------------------------
	///							DAO STORAGE
	/// ----------------------------------------------------------------------------------------

	// Gnosis multisendLibrary library contract // todo is this needed here?
	//address public multisendLibrary;

	// Contract generating uri for group tokens
	address private pfpExtension;

	uint256 public proposalCount;
	uint32 public votingPeriod;
	uint32 public memberLimit; // 1-100
	uint32 public tokenVoteThreshold; // 1-100
	uint32 public memberVoteThreshold; // 1-100

	string public docs;

	bytes32 public constant PROPOSAL_HASH = keccak256('SignProposal(uint256 proposal)');

	/**
	 * 'contractSignatureAllowance' provides the contract with the ability to 'sign' as an EOA would
	 * 	It enables signature based transactions on marketplaces accommodating the EIP-1271 standard.
	 *  Address is the account which makes the call to check the verified signature (ie. the martketplace).
	 * 	Bytes32 is the hash of the calldata which the group approves. This data is dependant
	 * 	on the marketplace / dex where the group are approving the transaction.
	 */
	mapping(address => mapping(bytes32 => uint256)) private contractSignatureAllowance;
	mapping(address => bool) public extensions;
	mapping(uint256 => Proposal) public proposals;
	mapping(ProposalType => VoteType) public proposalVoteTypes;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice init the group settings and mint membership for founders
	 * @param _initializationParams for the group, decoded to
	 * name_ name of the group
	 * symbol_ for the group token
	 * members_ initial members
	 * extensions_ initial extensions enabled
	 * govSettings_ settings for voting, proposals, and group size
	 */
	function setUp(bytes memory _initializationParams) public virtual override nonReentrant {
		if (votingPeriod != 0) revert AlreadyInitialized();

		(
			string memory name_,
			string memory symbol_,
			address[] memory members_,
			address[] memory extensions_,
			uint32[4] memory govSettings_
		) = abi.decode(_initializationParams, (string, string, address[], address[], uint32[4]));

		// SETUP FORUM GOVERNANCE //

		if (govSettings_[0] == 0 || govSettings_[0] > 365 days) revert PeriodBounds();

		if (govSettings_[1] > 100 || govSettings_[1] < members_.length)
			revert MemberLimitExceeded();

		if (govSettings_[2] < 1 || govSettings_[2] > 100) revert VoteThresholdBounds();

		if (govSettings_[3] < 1 || govSettings_[3] > 100) revert VoteThresholdBounds();

		ForumGovernance._init(name_, symbol_, members_);

		// Set the pfpSetter - determines uri of group token
		pfpExtension = extensions_[0];

		// Set the remaining base extensions (fundriase, withdrawal, + any custom extensions beyond that)
		// Cannot realistically overflow on human timescales
		unchecked {
			for (uint256 i = 1; i < extensions_.length; i++) {
				extensions[extensions_[i]] = true;
			}
		}

		memberCount = members_.length;

		votingPeriod = govSettings_[0];

		memberLimit = govSettings_[1];

		memberVoteThreshold = govSettings_[2];

		tokenVoteThreshold = govSettings_[3];

		// ALL PROPOSAL TYPES DEFAULT TO MEMBER VOTES //

		/// SETUP GNOSIS MODULE ///

		// ! Set the Gnosis safe address
		avatar = address(0);

		target = address(
			0
		); /*Set target to same address as avatar on setup - can be changed later via setTarget, though probably not a good idea*/
	}

	/// ----------------------------------------------------------------------------------------
	///							PROPOSAL LOGIC
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Get the proposal details for a given proposal
	 * @param proposal Index of the proposal
	 */
	function getProposalArrays(
		uint256 proposal
	)
		public
		view
		virtual
		returns (address[] memory accounts, uint256[] memory amounts, bytes[] memory payloads)
	{
		Proposal storage prop = proposals[proposal];

		(accounts, amounts, payloads) = (prop.accounts, prop.amounts, prop.payloads);
	}

	/**
	 * @notice Make a proposal to the group
	 * @param proposalType type of proposal
	 * @param accounts target accounts
	 * @param amounts to be sent
	 * @param payloads for target accounts
	 * @return proposal index of the created proposal
	 */
	function propose(
		ProposalType proposalType,
		address[] calldata accounts,
		uint256[] calldata amounts,
		bytes[] calldata payloads
	) public payable virtual nonReentrant returns (uint256 proposal) {
		if (accounts.length != amounts.length || amounts.length != payloads.length)
			revert NoArrayParity();

		if (proposalType == ProposalType.VPERIOD)
			if (amounts[0] == 0 || amounts[0] > 365 days) revert PeriodBounds();

		if (proposalType == ProposalType.MEMBER_LIMIT)
			if (amounts[0] > 100 || amounts[0] < memberCount) revert MemberLimitExceeded();

		if (
			proposalType == ProposalType.MEMBER_THRESHOLD ||
			proposalType == ProposalType.TOKEN_THRESHOLD
		)
			if (amounts[0] == 0 || amounts[0] > 100) revert VoteThresholdBounds();

		if (proposalType == ProposalType.TYPE)
			if (amounts[0] > 13 || amounts[1] > 2 || amounts.length != 2) revert TypeBounds();

		if (proposalType == ProposalType.MINT)
			if ((memberCount + accounts.length) > memberLimit) revert MemberLimitExceeded();

		// Cannot realistically overflow on human timescales
		unchecked {
			++proposalCount;
		}

		proposal = proposalCount;

		proposals[proposal] = Proposal({
			proposalType: proposalType,
			accounts: accounts,
			amounts: amounts,
			payloads: payloads,
			creationTime: _safeCastTo32(block.timestamp)
		});

		emit NewProposal(msg.sender, proposal, proposalType, accounts, amounts, payloads);
	}

	/**
	 * @notice Process a proposal
	 * @param proposal index of proposal
	 * @param signatures array of sigs of members who have voted for the proposal
	 * @return didProposalPass check if proposal passed
	 * @return results from any calls
	 * @dev signatures must be in ascending order
	 */
	function processProposal(
		uint256 proposal,
		Signature[] calldata signatures
	) public payable virtual nonReentrant returns (bool didProposalPass, bytes[] memory results) {
		Proposal storage prop = proposals[proposal];

		VoteType voteType = proposalVoteTypes[prop.proposalType];

		if (prop.creationTime == 0) revert NotCurrentProposal();

		uint256 votes;

		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PROPOSAL_HASH, proposal))
			)
		);

		// We keep track of the previous signer in the array to ensure there are no duplicates
		address prevSigner;

		// For each sig we check the recovered signer is a valid member and count thier vote
		for (uint256 i; i < signatures.length; ) {
			// Recover the signer
			address recoveredSigner = ecrecover(
				digest,
				signatures[i].v,
				signatures[i].r,
				signatures[i].s
			);

			// If not a member, or the signer is out of order (used to prevent duplicates), revert
			if (balanceOf[recoveredSigner][MEMBERSHIP] == 0 || prevSigner >= recoveredSigner)
				revert SignatureError();

			// If the signer has not delegated their vote, we count, otherwise we skip
			if (memberDelegatee[recoveredSigner] == address(0)) {
				// If member vote we increment by 1 (for the signer) + the number of members who have delegated to the signer
				// Else we calculate the number of votes based on share of the treasury
				if (voteType == VoteType.MEMBER)
					votes += 1 + EnumerableSet.length(memberDelegators[recoveredSigner]);
				else {
					uint256 len = EnumerableSet.length(memberDelegators[recoveredSigner]);
					// Add the number of votes the signer holds
					votes += balanceOf[recoveredSigner][TOKEN];
					// If the signer has been delegated too,check the balances of anyone who has delegated to the current signer
					if (len != 0)
						for (uint256 j; j < len; ) {
							votes += balanceOf[
								EnumerableSet.at(memberDelegators[recoveredSigner], j)
							][TOKEN];
							++j;
						}
				}
			}

			++i;
			prevSigner = recoveredSigner;
		}

		didProposalPass = _countVotes(voteType, votes);

		if (didProposalPass) {
			// Cannot realistically overflow on human timescales
			unchecked {
				if (prop.proposalType == ProposalType.MINT)
					for (uint256 i; i < prop.accounts.length; ) {
						// Only mint membership token if the account is not already a member
						if (balanceOf[prop.accounts[i]][MEMBERSHIP] == 0)
							_mint(prop.accounts[i], MEMBERSHIP, 1, '');
						_mint(prop.accounts[i], TOKEN, prop.amounts[i], '');
						++i;
					}

				if (prop.proposalType == ProposalType.BURN)
					for (uint256 i; i < prop.accounts.length; ) {
						_burn(prop.accounts[i], MEMBERSHIP, 1);
						_burn(prop.accounts[i], TOKEN, prop.amounts[i]);
						++i;
					}

				if (prop.proposalType == ProposalType.CALL) {
					for (uint256 i; i < prop.accounts.length; i++) {
						results = new bytes[](prop.accounts.length);

						(bool successCall, bytes memory result) = prop.accounts[i].call{
							value: prop.amounts[i]
						}(prop.payloads[i]);

						if (!successCall) revert CallError();

						results[i] = result;
					}
				}

				// Governance settings
				if (prop.proposalType == ProposalType.VPERIOD)
					votingPeriod = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.MEMBER_LIMIT)
					memberLimit = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.MEMBER_THRESHOLD)
					memberVoteThreshold = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.TOKEN_THRESHOLD)
					tokenVoteThreshold = uint32(prop.amounts[0]);

				if (prop.proposalType == ProposalType.TYPE)
					proposalVoteTypes[ProposalType(prop.amounts[0])] = VoteType(prop.amounts[1]);

				if (prop.proposalType == ProposalType.PAUSE) _flipPause();

				if (prop.proposalType == ProposalType.EXTENSION)
					for (uint256 i; i < prop.accounts.length; i++) {
						if (prop.amounts[i] != 0)
							extensions[prop.accounts[i]] = !extensions[prop.accounts[i]];

						if (prop.payloads[i].length > 3) {
							IForumGroupExtension(prop.accounts[i]).setExtension(prop.payloads[i]);
						}
					}

				if (prop.proposalType == ProposalType.ESCAPE) delete proposals[prop.amounts[0]];

				if (prop.proposalType == ProposalType.DOCS) docs = string(prop.payloads[0]);

				// TODO should be converted to set hash on gnosis safe
				if (prop.proposalType == ProposalType.ALLOW_CONTRACT_SIG) {
					// This sets the allowance for EIP-1271 contract signature transactions on marketplaces
					for (uint256 i; i < prop.accounts.length; i++) {
						contractSignatureAllowance[prop.accounts[i]][bytes32(prop.payloads[i])] = 1;
					}
				}

				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);

				// Delete proposal now that it has been processed
				delete proposals[proposal];
			}
		} else {
			// Only delete and update the proposal settings if there are not enough votes AND the time limit has passed
			// This prevents deleting proposals unfairly
			if (block.timestamp > prop.creationTime + votingPeriod) {
				emit ProposalProcessed(prop.proposalType, proposal, didProposalPass);

				delete proposals[proposal];
			}
		}
	}

	/**
	 * @notice Count votes on a proposal
	 * @param voteType voteType to count
	 * @param yesVotes number of votes for the proposal
	 * @return bool true if the proposal passed, false otherwise
	 */
	function _countVotes(VoteType voteType, uint256 yesVotes) internal view virtual returns (bool) {
		if (voteType == VoteType.MEMBER)
			if ((yesVotes * 100) / memberCount >= memberVoteThreshold) return true;

		if (voteType == VoteType.SIMPLE_MAJORITY)
			if (yesVotes > ((totalSupply * 50) / 100)) return true;

		if (voteType == VoteType.TOKEN_MAJORITY)
			if (yesVotes >= (totalSupply * tokenVoteThreshold) / 100) return true;

		return false;
	}

	/// ----------------------------------------------------------------------------------------
	///							EXTENSIONS
	/// ----------------------------------------------------------------------------------------

	modifier onlyExtension() {
		if (!extensions[msg.sender]) revert NotExtension();

		_;
	}

	/**
	 * @notice Interface to call an extension set by the group
	 * @param extension address of extension
	 * @param amount for extension
	 * @param extensionData data sent to extension to be decoded or used
	 * @return mint true if tokens are to be minted, false if to be burnt
	 * @return amountOut amount of token to mint/burn
	 */
	function callExtension(
		address extension,
		uint256 amount,
		bytes calldata extensionData
	) public payable virtual nonReentrant returns (bool mint, uint256 amountOut) {
		if (!extensions[extension]) revert NotExtension();

		(mint, amountOut) = IForumGroupExtension(extension).callExtension{value: msg.value}(
			msg.sender,
			amount,
			extensionData
		);

		if (mint) {
			if (amountOut != 0) _mint(msg.sender, TOKEN, amountOut, '');
		} else {
			if (amountOut != 0) _burn(msg.sender, TOKEN, amountOut);
		}
	}

	function mintShares(
		address to,
		uint256 id,
		uint256 amount
	) public payable virtual onlyExtension {
		_mint(to, id, amount, '');
	}

	function burnShares(
		address from,
		uint256 id,
		uint256 amount
	) public payable virtual onlyExtension {
		_burn(from, id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///							UTILITIES
	/// ----------------------------------------------------------------------------------------

	// 'id' not used but included to keep function signature of ERC1155
	function uri(uint256 tokenId) public view override returns (string memory) {
		return IPfpStaker(pfpExtension).getUri(address(this), name, tokenId);
	}

	receive() external payable virtual {}
}
