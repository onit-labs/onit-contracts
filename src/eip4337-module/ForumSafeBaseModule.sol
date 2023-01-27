// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {ForumGovernance, EnumerableSet, Enum} from './ForumSafe4337Governance.sol';
import {ForumSafe4337Module, IEntryPoint, IAccount} from './ForumSafe4337Module.sol';

import {NFTreceiver} from '@utils/NFTreceiver.sol';
import {ReentrancyGuard} from '@utils/ReentrancyGuard.sol';

import {IForumSafeModuleTypes} from '@interfaces/IForumSafe4337ModuleTypes.sol';
import {IForumGroupExtension} from '@interfaces/IForumGroupExtension.sol';

import 'forge-std/console.sol';

/**
 * @title ForumSafeModule
 * @notice Forum investment group governance extension for Gnosis Safe
 * @author Modified from KaliDAO (https://github.com/lexDAO/Kali/blob/main/contracts/KaliDAO.sol)
 */
contract ForumSafeBaseModule is
	IForumSafeModuleTypes,
	ForumSafe4337Module,
	ForumGovernance,
	ReentrancyGuard,
	NFTreceiver
{
	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error MemberLimitExceeded();

	error VoteThresholdBounds();

	error TypeBounds();

	error NoArrayParity();

	error NotExtension();

	error SignatureError();

	error CallError();

	/// ----------------------------------------------------------------------------------------
	///							DAO STORAGE
	/// ----------------------------------------------------------------------------------------

	// Contract generating uri for group tokens
	address private pfpExtension;

	uint32 public tokenVoteThreshold; // 1-100
	uint32 public memberVoteThreshold; // 1-100

	string public docs;

	bytes32 public constant PROPOSAL_HASH = keccak256('SignProposal(uint256 proposal)');

	// Enabled extensions which can interact with this contract
	mapping(address => bool) public extensions;

	// Vote type for each proposal type. eg. Member Limit Change = Token Vote (set to X% of token supply)
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
			uint32[2] memory _govSettings
		) = abi.decode(_initializationParams, (string, string, address, address[], uint32[2]));

		// Initialize ownership and transfer immediately to avatar
		// Ownable Init reverts if already initialized
		__Ownable_init();
		transferOwnership(_safe);

		/// SETUP GNOSIS MODULE ///
		avatar = _safe;
		target = _safe; /*Set target to same address as avatar on setup - can be changed later via setTarget, though probably not a good idea*/

		/// SETUP 4337 STORAGE ///
		_entryPoint = IEntryPoint(_extensions[0]);
		validationLogic = IAccount(_extensions[1]);

		/// SETUP FORUM GOVERNANCE ///
		if (_govSettings[0] < 1 || _govSettings[0] > 100) revert VoteThresholdBounds();

		if (_govSettings[1] < 1 || _govSettings[1] > 100) revert VoteThresholdBounds();

		ForumGovernance._init(_name, _symbol);

		// Set the pfpSetter - determines uri of group token
		pfpExtension = _extensions[2];

		// Set the remaining base extensions (fundriase, withdrawal, + any custom extensions beyond that)
		// Cannot realistically overflow on human timescales
		unchecked {
			for (uint256 i = 3; i < _extensions.length; ) {
				extensions[_extensions[i]] = true;
				++i;
			}
		}

		memberVoteThreshold = _govSettings[0];

		tokenVoteThreshold = _govSettings[1];

		/// ALL PROPOSAL TYPES DEFAULT TO MEMBER VOTES ///
	}

	/// ----------------------------------------------------------------------------------------
	///							MODULE LOGIC
	/// ----------------------------------------------------------------------------------------
	/**
	 * @notice Manage admin of module
	 */
	function manageAdmin(
		IForumSafeModuleTypes.ProposalType proposalType,
		address[] memory accounts,
		uint256[] memory amounts,
		bytes[] memory payloads
	) external payable {
		// ! count votes and limit to entrypoint or passed vote

		require(msg.sender == address(_entryPoint), 'Only entrypoint can execute');

		// Consider these checks which used to happen in propose function
		if (accounts.length != amounts.length || amounts.length != payloads.length)
			revert NoArrayParity();

		if (
			proposalType == ProposalType.MEMBER_THRESHOLD ||
			proposalType == ProposalType.TOKEN_THRESHOLD
		)
			if (amounts[0] == 0 || amounts[0] > 100) revert VoteThresholdBounds();

		// ! correct count based on new struct
		if (proposalType == ProposalType.TYPE)
			if (amounts[0] > 13 || amounts[1] > 2 || amounts.length != 2) revert TypeBounds();

		unchecked {
			if (proposalType == ProposalType.MEMBER_THRESHOLD)
				memberVoteThreshold = uint32(amounts[0]);

			if (proposalType == ProposalType.TOKEN_THRESHOLD)
				tokenVoteThreshold = uint32(amounts[0]);

			if (proposalType == ProposalType.TYPE)
				proposalVoteTypes[ProposalType(amounts[0])] = VoteType(amounts[1]);

			if (proposalType == ProposalType.PAUSE) _flipPause();

			if (proposalType == ProposalType.EXTENSION)
				for (uint256 i; i < accounts.length; ) {
					if (amounts[i] != 0) extensions[accounts[i]] = !extensions[accounts[i]];

					if (payloads[i].length > 3) {
						IForumGroupExtension(accounts[i]).setExtension(payloads[i]);
					}
					++i;
				}

			if (proposalType == ProposalType.DOCS) docs = string(payloads[0]);

			// ! consider a nonce or similar to prevent replies (if sigs are used)
		}
	}

	/**
	 * @notice Execute a proposal
	 * @param proposal encoded proposal details
	 * @return results from any calls
	 * @dev signatures must be in ascending order
	 */
	function execute(
		bytes calldata proposal
	) public virtual nonReentrant returns (bytes[] memory results) {
		// ! count votes and limit to entrypoint or passed vote or module

		require(msg.sender == address(_entryPoint), 'Only entrypoint can execute');

		(
			Enum.Operation operationType,
			address[] memory accounts,
			uint256[] memory amounts,
			bytes[] memory payloads
		) = abi.decode(proposal, (Enum.Operation, address[], uint256[], bytes[]));

		unchecked {
			// ! consider need for for loop, as opposed to only multisend via safe (maybe useful for extensions)
			for (uint256 i; i < accounts.length; ) {
				results = new bytes[](accounts.length);

				(bool successCall, bytes memory result) = execAndReturnData(
					accounts[i],
					amounts[i],
					payloads[i],
					Enum.Operation(operationType)
				);

				if (!successCall) revert CallError();

				results[i] = result;
				++i;
			}

			// ! consider a nonce or similar to prevent replies (if sigs are used)
		}
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

	function uri(uint256 tokenId) public view override returns (string memory) {
		(, bytes memory pfp) = pfpExtension.staticcall(
			abi.encodeWithSignature('getUri(address,string,uint256)', address(this), name, tokenId)
		);
		return string(pfp);
	}

	// // Workaround to importing basewallet here
	// function getEntryPoint() internal view returns (address) {
	// 	(, bytes memory res) = address(this).staticcall(abi.encodeWithSignature('entryPoint()'));
	// 	return abi.decode(res, (address));
	// }

	// // ! consider moving the below 2 functions to a library
	// /**
	//  * @notice Count votes on a proposal
	//  * @param voteType voteType to count
	//  * @param yesVotes number of votes for the proposal
	//  * @return bool true if the proposal passed, false otherwise
	//  */
	// function _countVotes(VoteType voteType, uint256 yesVotes) internal view returns (bool) {
	// 	if (voteType == VoteType.MEMBER)
	// 		if ((yesVotes * 100) / getOwners().length >= memberVoteThreshold) return true;

	// 	if (voteType == VoteType.SIMPLE_MAJORITY)
	// 		if (yesVotes > ((totalSupply * 50) / 100)) return true;

	// 	if (voteType == VoteType.TOKEN_MAJORITY)
	// 		if (yesVotes >= (totalSupply * tokenVoteThreshold) / 100) return true;

	// 	return false;
	// }

	// function _getVotes(
	// 	bytes calldata proposal,
	// 	IForumSafeModuleTypes.Signature[] memory signatures,
	// 	IForumSafeModuleTypes.VoteType voteType
	// ) internal view returns (uint256 votes) {
	// 	// We keep track of the previous signer in the array to ensure there are no duplicates
	// 	address prevSigner;

	// 	// ! consider some digest to secure executions - maybe using nonce
	// 	bytes32 digest = keccak256(
	// 		abi.encodePacked(
	// 			'\x19\x01',
	// 			DOMAIN_SEPARATOR(),
	// 			keccak256(abi.encode(PROPOSAL_HASH, proposal))
	// 		)
	// 	);

	// 	uint256 sigCount = signatures.length;

	// 	// For each sig we check the recovered signer is a valid member and count thier vote
	// 	for (uint256 i; i < sigCount; ) {
	// 		// Recover the signer
	// 		address recoveredSigner = ecrecover(
	// 			digest,
	// 			signatures[i].v,
	// 			signatures[i].r,
	// 			signatures[i].s
	// 		);

	// 		// If not a member, or the signer is out of order (used to prevent duplicates), revert
	// 		if (!isOwner(recoveredSigner) || prevSigner >= recoveredSigner) revert SignatureError();

	// 		// If the signer has not delegated their vote, we count, otherwise we skip
	// 		if (memberDelegatee[recoveredSigner] == address(0)) {
	// 			// If member vote we increment by 1 (for the signer) + the number of members who have delegated to the signer
	// 			// Else we calculate the number of votes based on share of the treasury
	// 			if (voteType == VoteType.MEMBER)
	// 				votes += 1 + EnumerableSet.length(memberDelegators[recoveredSigner]);
	// 			else {
	// 				uint256 len = EnumerableSet.length(memberDelegators[recoveredSigner]);
	// 				// Add the number of votes the signer holds
	// 				votes += balanceOf[recoveredSigner][TOKEN];
	// 				// If the signer has been delegated too,check the balances of anyone who has delegated to the current signer
	// 				if (len != 0)
	// 					for (uint256 j; j < len; ) {
	// 						votes += balanceOf[
	// 							EnumerableSet.at(memberDelegators[recoveredSigner], j)
	// 						][TOKEN];
	// 						++j;
	// 					}
	// 			}
	// 		}

	// 		// Increment the index and set the previous signer
	// 		++i;
	// 		prevSigner = recoveredSigner;
	// 	}
	// }

	receive() external payable virtual {}
}
