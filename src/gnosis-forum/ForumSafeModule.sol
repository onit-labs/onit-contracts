// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {ForumGovernance, EnumerableSet, Enum} from './ForumSafeGovernance.sol';

import {NFTreceiver} from '@utils/NFTreceiver.sol';
import {ProposalPacker} from '@utils/ProposalPacker.sol';
import {ReentrancyGuard} from '@utils/ReentrancyGuard.sol';
import {Utils} from '@utils/Utils.sol';

import {IForumSafeModuleTypes} from '@interfaces/IForumSafeModuleTypes.sol';
import {IForumGroupExtension} from '@interfaces/IForumGroupExtension.sol';

import {BaseAccount, UserOperation, IEntryPoint} from '@account-abstraction/core/BaseAccount.sol';
import 'forge-std/console.sol';

/**
 * @title ForumSafeModule
 * @notice Forum investment group governance extension for Gnosis Safe
 * @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)
 * @dev A first pass at integrating 4337 with ForumSafeModule
 * - proposal function remains but will be removed in future
 * - propose and process are restricted to entrypoint or sig count only
 * - functions can be called if validateSig passes, or called directly
 * - extensions and call extension etc exist as before
 * - BaseAccount, ForumGovernace, and Safe Module logic are all in this contract
 *   should attempt to remove these and use a logic contract with delegate
 * - // ! need to consider role of nonce in relation to general module / safe transactions
 */
contract ForumSafeModule is
	IForumSafeModuleTypes,
	ForumGovernance,
	BaseAccount,
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

	address _entryPoint;

	uint256 public proposalCount;
	uint32 public votingPeriod;
	uint32 public memberLimit; // 1-100
	uint32 public tokenVoteThreshold; // 1-100
	uint32 public memberVoteThreshold; // 1-100

	string public docs;

	bytes32 public constant PROPOSAL_HASH = keccak256('SignProposal(uint256 proposal)');

	// Enabled extensions which can interact with this contract
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
	 * @param _initializationParams for the group
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
		__Ownable_init();
		transferOwnership(_safe);

		/// SETUP GNOSIS MODULE ///
		avatar = _safe;
		target = _safe; /*Set target to same address as avatar on setup - can be changed later via setTarget, though probably not a good idea*/

		// SETUP ENTRYPOINT
		// ! remove hardcoding and add an update function
		_entryPoint = address(0xA12E9172eB5A8B9054F897cC231Cd7a2751D6D93);
		console.log('entrypoint', _entryPoint);

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
			for (uint256 i = 1; i < _extensions.length; ) {
				extensions[_extensions[i]] = true;
				++i;
			}
		}

		votingPeriod = _govSettings[0];

		memberLimit = _govSettings[1];

		memberVoteThreshold = _govSettings[2];

		tokenVoteThreshold = _govSettings[3];

		/// ALL PROPOSAL TYPES DEFAULT TO MEMBER VOTES ///
	}

	// ! potentially move this into seperate file
	/// ----------------------------------------------------------------------------------------
	///							4337 LOGIC
	/// ----------------------------------------------------------------------------------------

	// ! consider nonce in relation to general module / safe transactions
	// do we increment it for each entry point tx only? or every tx including extensions?
	function nonce() public view virtual override returns (uint256) {
		// return _nonce;
	}

	// ! consider entry point and where it is set / how it is updated
	function entryPoint() public view virtual override returns (IEntryPoint) {
		return IEntryPoint(_entryPoint);
	}

	/// implement template method of BaseAccount
	function _validateSignature(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		address
	) internal virtual override returns (uint256 sigTimeRange) {
		// userOp.sigs should be a hash of the userOpHash, and the proposal hash for this contract
		console.log('_validateSignature');
		// ! improve signature format, remove Signature type
		// ! consider more general validation -> only process will work for now
		// ! consider restrictions on what entrypoint can call?

		// extract individual sigs from userOp.signature
		// userOpHash to ethSignedMessageHash
		// validate each sig against the eerecovered hash

		// The calldata should be a call to process a proposal
		// If called from entry point, sigs should be empty
		(uint256 proposal, Signature[] memory signatures) = abi.decode(
			userOp.callData[4:],
			(uint256, Signature[])
		);

		console.log('proposal', proposal);

		// Construct what the hash should be
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PROPOSAL_HASH, proposal))
			)
		);

		// Full digest which the signatures from userOp should have signed
		bytes32 fullDigest = keccak256(abi.encode(digest, userOpHash));

		// How many sigs were sent in userOp
		uint256 sigCount = userOp.signature.length / 65;

		// unpack propdetails
		(, uint8 p, ) = unpackProposal(proposals[proposal].proposalDetails);

		VoteType voteType = VoteType(p);

		address prevSigner;

		uint256 votes;

		// For each sig we check the recovered signer is a valid member and count thier vote
		for (uint256 i; i < sigCount; ) {
			// Recover the signer
			address recoveredSigner = ecrecover(
				fullDigest,
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

		return _countVotes(voteType, votes) ? 0 : SIG_VALIDATION_FAILED;
	}

	/// implement template method of BaseAccount
	function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {
		//require(_nonce++ == userOp.nonce, 'account: invalid nonce');
	}

	function getRequiredSignatures() public view virtual returns (uint256) {
		// ! implement argent style check on allowed methods for single signer vs all sigs

		// check functions on this contract
		// check functions as the module
		// check batched or multicall calls

		return 0;
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

		didProposalPass = _countVotes(voteType, _getVotes(proposal, signatures, voteType));

		if (didProposalPass) {
			// Cannot realistically overflow on human timescales
			unchecked {
				if (proposalType == ProposalType.CALL) {
					for (uint256 i; i < prop.accounts.length; ) {
						results = new bytes[](prop.accounts.length);

						(bool successCall, bytes memory result) = execAndReturnData(
							prop.accounts[i],
							prop.amounts[i],
							prop.payloads[i],
							Enum.Operation(operation)
						);

						if (!successCall) revert CallError();

						results[i] = result;
						++i;
					}

					// If member limit is exceeed, revert
					if (getOwners().length > memberLimit) revert MemberLimitExceeded();
				}

				// Governance settings
				if (proposalType == ProposalType.VPERIOD) votingPeriod = uint32(prop.amounts[0]);

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
					for (uint256 i; i < prop.accounts.length; ) {
						if (prop.amounts[i] != 0)
							extensions[prop.accounts[i]] = !extensions[prop.accounts[i]];

						if (prop.payloads[i].length > 3) {
							IForumGroupExtension(prop.accounts[i]).setExtension(prop.payloads[i]);
						}
						++i;
					}

				if (proposalType == ProposalType.ESCAPE) delete proposals[prop.amounts[0]];

				if (proposalType == ProposalType.DOCS) docs = string(prop.payloads[0]);

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
	function _countVotes(VoteType voteType, uint256 yesVotes) private view returns (bool) {
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

	function _getVotes(
		uint256 proposal,
		IForumSafeModuleTypes.Signature[] memory signatures,
		IForumSafeModuleTypes.VoteType voteType
	) private view returns (uint256 votes) {
		// We keep track of the previous signer in the array to ensure there are no duplicates
		address prevSigner;

		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				DOMAIN_SEPARATOR(),
				keccak256(abi.encode(PROPOSAL_HASH, proposal))
			)
		);

		uint256 sigCount = signatures.length;

		// For each sig we check the recovered signer is a valid member and count thier vote
		for (uint256 i; i < sigCount; ) {
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
