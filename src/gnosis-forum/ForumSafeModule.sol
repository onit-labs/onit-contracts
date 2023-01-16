// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {ForumGovernance, EnumerableSet, Enum} from './ForumSafeGovernance.sol';

import {NFTreceiver} from '@utils/NFTreceiver.sol';
import {ProposalPacker} from '@utils/ProposalPacker.sol';
import {ReentrancyGuard} from '@utils/ReentrancyGuard.sol';

import {IForumSafeModuleTypes} from '@interfaces/IForumSafeModuleTypes.sol';
import {IForumGroupExtension} from '@interfaces/IForumGroupExtension.sol';

/**
 * @title ForumSafeModule
 * @notice Forum investment group governance extension for Gnosis Safe
 * @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)
 */
contract ForumSafeModule is
	IForumSafeModuleTypes,
	ForumGovernance,
	ReentrancyGuard,
	ProposalPacker,
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

	error MemberLimitExceeded();

	error PeriodBounds();

	error VoteThresholdBounds();

	error TypeBounds();

	error NoArrayParity();

	error NotCurrentProposal();

	error NotExtension();

	error SignatureError();

	error CallError();

	error AvatarOnly();

	/// ----------------------------------------------------------------------------------------
	///							DAO STORAGE
	/// ----------------------------------------------------------------------------------------

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

	/// @dev This constructor ensures that this contract can only be used as a master copy for Proxy contracts
	constructor() initializer {
		// By setting the owner it is not possible to call setUp
		// This is an unusable Forum group, perfect for the singleton
		__Ownable_init();
		transferOwnership(address(0xdead));
	}

	/**
	 * @notice init the group settings and mint membership for founders
	 * @param _initializationParams for the group, decoded to:
	 * 	(_name ,_symbol ,_extension ,_govSettings)
	 */
	function setUp(
		bytes memory _initializationParams
	) public virtual override initializer nonReentrant {
		(
			string memory _name,
			string memory _symbol,
			address _safe,
			address[] memory _extensions,
			uint32[4] memory _govSettings
		) = abi.decode(_initializationParams, (string, string, address, address[], uint32[4]));

		// Initialize ownership and transfer immediately to avatar
		// Ownable Init reverts if already initialized
		// TODO consider owner being safe
		__Ownable_init();
		transferOwnership(_safe);

		/// SETUP GNOSIS MODULE ///
		avatar = _safe;
		target = _safe; /*Set target to same address as avatar on setup - can be changed later via setTarget, though probably not a good idea*/

		/// SETUP FORUM GOVERNANCE ///
		if (_govSettings[0] == 0 || _govSettings[0] > 365 days) revert PeriodBounds();

		if (_govSettings[1] > 100 || _govSettings[1] < getOwners().length)
			revert MemberLimitExceeded();

		if (_govSettings[2] < 1 || _govSettings[2] > 100) revert VoteThresholdBounds();

		if (_govSettings[3] < 1 || _govSettings[3] > 100) revert VoteThresholdBounds();

		ForumGovernance._init(_name, _symbol);

		// Set the pfpSetter - determines uri of group token
		pfpExtension = _extensions[0];

		// Set the remaining base extensions (fundriase, withdrawal, + any custom extensions beyond that)
		// Cannot realistically overflow on human timescales
		unchecked {
			for (uint256 i = 1; i < _extensions.length; i++) {
				extensions[_extensions[i]] = true;
			}
		}

		votingPeriod = _govSettings[0];

		memberLimit = _govSettings[1];

		memberVoteThreshold = _govSettings[2];

		tokenVoteThreshold = _govSettings[3];

		/// ALL PROPOSAL TYPES DEFAULT TO MEMBER VOTES ///
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
		external
		view
		virtual
		returns (address[] memory accounts, uint256[] memory amounts, bytes[] memory payloads)
	{
		Proposal storage prop = proposals[proposal];

		(accounts, amounts, payloads) = (prop.accounts, prop.amounts, prop.payloads);
	}

	/**
	 * @notice Make a proposal to the group
	 * @param proposalType type of proposal on module
	 * @param operationType type of operation if executed on safe
	 * @param accounts target accounts
	 * @param amounts to be sent
	 * @param payloads for target accounts
	 * @return proposal index of the created proposal
	 */
	function propose(
		IForumSafeModuleTypes.ProposalType proposalType,
		Enum.Operation operationType,
		address[] calldata accounts,
		uint256[] calldata amounts,
		bytes[] calldata payloads
	) public payable virtual nonReentrant returns (uint256 proposal) {
		if (accounts.length != amounts.length || amounts.length != payloads.length)
			revert NoArrayParity();

		if (proposalType == ProposalType.VPERIOD)
			if (amounts[0] == 0 || amounts[0] > 365 days) revert PeriodBounds();

		if (proposalType == ProposalType.MEMBER_LIMIT)
			if (amounts[0] > 100 || amounts[0] < getOwners().length) revert MemberLimitExceeded();

		if (
			proposalType == ProposalType.MEMBER_THRESHOLD ||
			proposalType == ProposalType.TOKEN_THRESHOLD
		)
			if (amounts[0] == 0 || amounts[0] > 100) revert VoteThresholdBounds();

		if (proposalType == ProposalType.TYPE)
			if (amounts[0] > 13 || amounts[1] > 2 || amounts.length != 2) revert TypeBounds();

		// Cannot realistically overflow on human timescales
		unchecked {
			++proposalCount;
		}

		proposal = proposalCount;

		proposals[proposal] = Proposal({
			proposalDetails: packProposal(
				uint32(block.timestamp),
				uint8(proposalType),
				uint8(operationType)
			),
			accounts: accounts,
			amounts: amounts,
			payloads: payloads
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

		// Unpack the proposal details
		(uint32 creationTime, uint8 proposalTypeUint, uint8 operation) = unpackProposal(
			prop.proposalDetails
		);
		// Convert the proposal type to an enum
		ProposalType proposalType = ProposalType(proposalTypeUint);
		// Get the vote type for the proposal
		VoteType voteType = proposalVoteTypes[proposalType];

		if (creationTime == 0) revert NotCurrentProposal();

		uint256 votes = getVotes(proposal, signatures, voteType);

		didProposalPass = _countVotes(voteType, votes);

		if (didProposalPass) {
			// Cannot realistically overflow on human timescales
			unchecked {
				if (proposalType == ProposalType.CALL) {
					for (uint256 i; i < prop.accounts.length; i++) {
						results = new bytes[](prop.accounts.length);

						(bool successCall, bytes memory result) = execAndReturnData(
							prop.accounts[i],
							prop.amounts[i],
							prop.payloads[i],
							Enum.Operation(operation)
						);

						if (!successCall) revert CallError();

						results[i] = result;
					}

					// If member limit is exceeed, revert
					if (getOwners().length > memberLimit) revert MemberLimitExceeded();
				}

				// Governance settings
				if (proposalType == ProposalType.VPERIOD) votingPeriod = uint32(prop.amounts[0]);

				// ! consider member limit when owners are on safe
				if (proposalType == ProposalType.MEMBER_LIMIT)
					memberLimit = uint32(prop.amounts[0]);

				if (proposalType == ProposalType.MEMBER_THRESHOLD)
					memberVoteThreshold = uint32(prop.amounts[0]);

				if (proposalType == ProposalType.TOKEN_THRESHOLD)
					tokenVoteThreshold = uint32(prop.amounts[0]);

				if (proposalType == ProposalType.TYPE)
					proposalVoteTypes[ProposalType(prop.amounts[0])] = VoteType(prop.amounts[1]);

				if (proposalType == ProposalType.PAUSE) _flipPause();

				if (proposalType == ProposalType.EXTENSION)
					for (uint256 i; i < prop.accounts.length; i++) {
						if (prop.amounts[i] != 0)
							extensions[prop.accounts[i]] = !extensions[prop.accounts[i]];

						if (prop.payloads[i].length > 3) {
							IForumGroupExtension(prop.accounts[i]).setExtension(prop.payloads[i]);
						}
					}

				if (proposalType == ProposalType.ESCAPE) delete proposals[prop.amounts[0]];

				if (proposalType == ProposalType.DOCS) docs = string(prop.payloads[0]);

				// TODO should be converted to set hash on gnosis safe
				if (proposalType == ProposalType.ALLOW_CONTRACT_SIG) {
					// This sets the allowance for EIP-1271 contract signature transactions on marketplaces
					for (uint256 i; i < prop.accounts.length; i++) {
						// set the sig on the gnosis safe
					}
				}

				emit ProposalProcessed(proposalType, proposal, didProposalPass);

				// Delete proposal now that it has been processed
				delete proposals[proposal];
			}
		} else {
			// Only delete and update the proposal settings if there are not enough votes AND the time limit has passed
			// This prevents deleting proposals unfairly
			if (block.timestamp > creationTime + votingPeriod) {
				emit ProposalProcessed(proposalType, proposal, didProposalPass);

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
			if ((yesVotes * 100) / getOwners().length >= memberVoteThreshold) return true;

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

	modifier avatarOnly() {
		if (msg.sender != avatar) revert AvatarOnly();
		_;
	}

	function uri(uint256 tokenId) public view override returns (string memory) {
		(, bytes memory pfp) = pfpExtension.staticcall(
			abi.encodeWithSignature('getUri(address,string,uint256)', address(this), name, tokenId)
		);
		return string(pfp);
	}

	/**
	 * @notice Execute a transaction as a module
	 * @dev Can be used to execute arbitrary code if needed, only when called by safe
	 * @param _to address to send transaction to
	 * @param _value value to send with transaction
	 * @param _data data to send with transaction
	 */
	function executeAsModule(
		address _to,
		uint256 _value,
		bytes calldata _data
	) external avatarOnly {
		(bool success, ) = _to.call{value: _value}(_data);
		if (!success) revert CallError();
	}

	function getVotes(
		uint256 proposal,
		IForumSafeModuleTypes.Signature[] memory signatures,
		IForumSafeModuleTypes.VoteType voteType
	) internal view returns (uint256 votes) {
		// We keep track of the previous signer in the array to ensure there are no duplicates
		address prevSigner;

		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PROPOSAL_HASH, proposal))
			)
		);

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
			if (!isOwner(recoveredSigner) || prevSigner >= recoveredSigner) revert SignatureError();

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

			// Increment the index and set the previous signer
			++i;
			prevSigner = recoveredSigner;
		}
	}

	receive() external payable virtual {}
}
