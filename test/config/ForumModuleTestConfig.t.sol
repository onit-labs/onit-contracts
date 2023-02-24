// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Module, Enum} from '@gnosis.pm/zodiac/contracts/core/Module.sol';

// Forum imports
import {ForumSafeFactory} from '../../src/gnosis-forum/ForumSafeFactory.sol';
import {ForumSafeModule} from '../../src/gnosis-forum/ForumSafeModule.sol';

// Forum extension imports
import {ForumFundraiseExtension} from '../../src/gnosis-forum/extensions/fundraise/ForumFundraiseExtension.sol';
import {ForumWithdrawalExtension} from '../../src/gnosis-forum/extensions/withdrawal/ForumWithdrawalExtension.sol';

// Forum interfaces
import {IForumSafeModuleTypes} from '../../src/interfaces/IForumSafeModuleTypes.sol';

import './BasicTestConfig.t.sol';

// Config for the Forum Module
abstract contract ForumModuleTestConfig is BasicTestConfig {
	// Forum contract types
	ForumSafeModule internal forumSafeModuleSingleton;
	ForumSafeFactory internal forumSafeFactory;

	// Forum extensions
	ForumFundraiseExtension internal fundraiseExtension;
	ForumWithdrawalExtension internal withdrawalExtension;

	// Declare arrys used to setup forum groups
	address[] internal voters = new address[](1);
	address[] internal initialExtensions = new address[](1);

	address internal moduleAddress;
	address internal fundraiseAddress;
	address internal withdrawalAddress;
	address internal pfpAddress;

	// id of gov token on forum module
	uint256 internal constant TOKEN = 0;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	constructor() {
		forumSafeModuleSingleton = new ForumSafeModule();

		voters[0] = alice;
	}

	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------

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
}
