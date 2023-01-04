// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {GnosisSafe} from '@gnosis/GnosisSafe.sol';
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';
import {MultiSend} from '@gnosis/libraries/MultiSend.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';

import {ForumSafeFactory} from '../../../src/gnosis-forum/ForumSafeFactory.sol';
import {ForumSafeModule} from '../../../src/gnosis-forum/ForumSafeModule.sol';

import {ERC721Test} from '../../../src/Test/ERC721Test.sol';
import {ERC1155Test} from '../../../src/Test/ERC1155Test.sol';

import {IForumGroupTypes} from '../../../src/interfaces/IForumGroupTypes.sol';

import 'forge-std/Test.sol';
import 'forge-std/StdCheats.sol';
import 'forge-std/console.sol';

abstract contract ForumSafeTestConfig is Test {
	// Safe contract types
	GnosisSafe internal safeSingleton;
	MultiSend internal multisend;
	CompatibilityFallbackHandler internal handler;
	GnosisSafeProxyFactory internal safeProxyFactory;
	// sigMessageLib -> get when needed for 1271 tests

	// Forum contract types
	ForumSafeModule internal forumSafeModule;
	ForumSafeFactory internal forumSafeFactory;

	address internal alice;
	uint256 internal alicePk;

	// Declare arrys used to setup forum groups
	address[] internal voters = new address[](1);
	address[] internal initialExtensions = new address[](1);

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	constructor() {
		(alice, alicePk) = makeAddrAndKey('alice');

		safeSingleton = new GnosisSafe();
		multisend = new MultiSend();
		handler = new CompatibilityFallbackHandler();
		safeProxyFactory = new GnosisSafeProxyFactory();

		forumSafeModule = new ForumSafeModule();
		forumSafeFactory = new ForumSafeFactory(
			alice,
			payable(address(forumSafeModule)),
			address(safeSingleton),
			address(handler),
			address(multisend),
			address(safeProxyFactory)
		);
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
		bytes32 digest = keccak256(
			abi.encodePacked(
				'\x19\x01',
				group.DOMAIN_SEPARATOR(),
				keccak256(abi.encode(group.PROPOSAL_HASH(), proposal))
			)
		);

		(uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
		IForumGroupTypes.Signature[] memory signatures = new IForumGroupTypes.Signature[](1);
		signatures[0] = IForumGroupTypes.Signature(v, r, s);

		if (expectPass) {
			group.processProposal(proposal, signatures);
		} else {
			vm.expectRevert();
			group.processProposal(proposal, signatures);
		}
	}
}
