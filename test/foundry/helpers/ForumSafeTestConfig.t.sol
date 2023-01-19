// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Module, Enum} from '@gnosis.pm/zodiac/contracts/core/Module.sol';

// Gnosis Safe imports
import {GnosisSafe} from '@gnosis/GnosisSafe.sol';
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';
import {MultiSend} from '@gnosis/libraries/MultiSend.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';
import {SignMessageLib} from '@gnosis/examples/libraries/SignMessage.sol';

// Forum imports
import {ForumSafeFactory} from '../../../src/gnosis-forum/ForumSafeFactory.sol';
import {ForumSafeModule} from '../../../src/gnosis-forum/ForumSafeModule.sol';

// Forum extension imports
import {ForumFundraiseExtension} from '../../../src/gnosis-forum/extensions/fundraise/ForumFundraiseExtension.sol';
import {ForumWithdrawalExtension} from '../../../src/gnosis-forum/extensions/withdrawal/ForumWithdrawalExtension.sol';

// Forum interfaces
import {IForumSafeModuleTypes} from '../../../src/interfaces/IForumSafeModuleTypes.sol';

import './BasicTestConfig.t.sol';

abstract contract ForumSafeTestConfig is BasicTestConfig {
	// Safe contract types
	GnosisSafe internal safeSingleton;
	MultiSend internal multisend;
	CompatibilityFallbackHandler internal handler;
	GnosisSafeProxyFactory internal safeProxyFactory;
	SignMessageLib internal signMessageLib;

	// Forum contract types
	ForumSafeModule internal forumSafeModuleSingleton;
	ForumSafeFactory internal forumSafeFactory;

	// Forum extensions
	ForumFundraiseExtension internal fundraiseExtension;
	ForumWithdrawalExtension internal withdrawalExtension;

	// Declare arrys used to setup forum groups
	address[] internal voters = new address[](1);
	address[] internal initialExtensions = new address[](1);

	address internal zeroAddress = address(0);
	address internal oneAddress = address(1);

	address internal safeAddress;
	address internal moduleAddress;
	address internal fundraiseAddress;

	// id of gov token on forum module
	uint256 TOKEN = 0;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	constructor() {
		safeSingleton = new GnosisSafe();
		multisend = new MultiSend();
		handler = new CompatibilityFallbackHandler();
		safeProxyFactory = new GnosisSafeProxyFactory();
		signMessageLib = new SignMessageLib();

		forumSafeModuleSingleton = new ForumSafeModule();
		forumSafeFactory = new ForumSafeFactory(
			alice,
			payable(address(forumSafeModuleSingleton)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory),
			address(fundraiseExtension),
			address(withdrawalExtension),
			address(0) // pfpSetter - not used in tests
		);

		voters[0] = alice;
	}

	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------

	/**
	 * @notice Util to process a proposal with alice signing
	 * @param proposal The id of the proposal to process
	 * @param group The forum group to process the proposal for
	 * @param expectPass Whether the prop should pass, or we check for a revert
	 */
	function processProposal(uint256 proposal, ForumSafeModule group, bool expectPass) internal {
		// Sign the proposal number 1 as alice and process
		IForumSafeModuleTypes.Signature[] memory signatures = signProposal(
			proposal,
			group,
			alicePk
		);

		if (expectPass) {
			group.processProposal(proposal, signatures);
		} else {
			vm.expectRevert();
			group.processProposal(proposal, signatures);
		}
	}

	/**
	 * @notice Sign proposal
	 * @param proposal The id of the proposal to sign
	 * @param group The forum group to sign the proposal for
	 * @param signerPk The address of the signer
	 * @return The signatures
	 */
	function signProposal(
		uint256 proposal,
		ForumSafeModule group,
		uint256 signerPk
	) internal view returns (IForumSafeModuleTypes.Signature[] memory) {
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				group.DOMAIN_SEPARATOR(),
				keccak256(abi.encode(group.PROPOSAL_HASH(), proposal))
			)
		);

		(uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
		IForumSafeModuleTypes.Signature[] memory signatures = new IForumSafeModuleTypes.Signature[](
			1
		);
		signatures[0] = IForumSafeModuleTypes.Signature(v, r, s);
		return signatures;
	}

	function buildDynamicArraysForProposal(
		address[1] memory _accounts,
		uint256[1] memory _amounts,
		bytes[1] memory _payloads
	)
		internal
		pure
		returns (address[] memory accounts, uint256[] memory amounts, bytes[] memory payloads)
	{
		accounts = new address[](_accounts.length);
		amounts = new uint256[](_amounts.length);
		payloads = new bytes[](_payloads.length);

		for (uint256 i = 0; i < _accounts.length; i++) {
			accounts[i] = _accounts[i];
			amounts[i] = _amounts[i];
			payloads[i] = _payloads[i];
		}
	}

	// For now this works for simple, 1 account, 1 amount, 1 payload peoposals
	function proposeToForum(
		ForumSafeModule group,
		IForumSafeModuleTypes.ProposalType proposalType,
		Enum.Operation operationType,
		address[1] memory accounts,
		uint256[1] memory amounts,
		bytes[1] memory payloads
	) internal returns (uint256) {
		(
			address[] memory _accounts,
			uint256[] memory _amounts,
			bytes[] memory _payloads
		) = buildDynamicArraysForProposal(accounts, amounts, payloads);

		return group.propose(proposalType, operationType, _accounts, _amounts, _payloads);
	}

	function buildSafeMultisend(
		Enum.Operation operation,
		address to,
		uint256 value,
		bytes memory data
	) internal pure returns (bytes memory) {
		// Encode the multisend transaction
		// (needed to delegate call from the safe as addModule is 'authorised')
		bytes memory tmp = abi.encodePacked(operation, to, value, uint256(data.length), data);

		// Create multisend payload
		return abi.encodeWithSignature('multiSend(bytes)', tmp);
	}
}
