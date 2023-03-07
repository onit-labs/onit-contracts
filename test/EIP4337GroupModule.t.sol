// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// import './helpers/ForumSafeTestConfig.t.sol';
import './config/EIP4337TestConfig.t.sol';

import {SignatureHelper} from './config/SignatureHelper.t.sol';

contract Module4337Test is EIP4337TestConfig, SignatureHelper {
	ForumGroupModule private forumSafeModule;
	GnosisSafe private safe;

	// Some public keys used as signers in tests
	uint256[2] internal publicKey;
	uint256[2] internal publicKey2;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		publicKey = createPublicKey();
		publicKey2 = createPublicKey();

		uint256[] memory membersX = new uint256[](2);
		membersX[0] = publicKey[0];
		membersX[1] = publicKey2[0];

		uint256[] memory membersY = new uint256[](2);
		membersY[0] = publicKey[1];
		membersY[1] = publicKey2[1];

		(
			// Deploy a forum safe from the factory
			forumSafeModule,
			safe
		) = forumGroupFactory.deployForumGroup('test', membersX, membersY);

		// Deal the account some funds
		vm.deal(address(safe), 1 ether);
	}

	/// -----------------------------------------------------------------------
	/// Tests
	/// -----------------------------------------------------------------------

	function testSetupGroup() public {
		// check the members are set
		uint256[2][] memory members = forumSafeModule.getMembers();

		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(members[1][0] == publicKey2[0]);
		assertTrue(members[1][1] == publicKey2[1]);
	}

	function testExecutionViaEntryPoint() public {
		// check balance before
		assertTrue(address(alice).balance == 1 ether);
		assertTrue(address(safe).balance == 1 ether);
		assertTrue(forumSafeModule.nonce() == 0);

		// Build a transaction to execute
		bytes memory executeCalldata = buildExecutionPayload(
			alice,
			uint256(0.5 ether),
			new bytes(0),
			Enum.Operation.Call
		);

		// Build user operation
		UserOperation memory tmp = buildUserOp(
			address(forumSafeModule),
			forumSafeModule.nonce(),
			new bytes(0),
			executeCalldata
		);

		// Get signatures for the user operation
		uint256[2] memory s1 = signMessageForPublicKey(entryPoint.getUserOpHash(tmp), publicKey);
		//uint256[2] memory s2 = signMessageForPublicKey(entryPoint.getUserOpHash(tmp), publicKey2);

		uint256[2][] memory sigs = new uint256[2][](2);
		sigs[0] = s1;
		//sigs[1] = s2;

		tmp.signature = abi.encode(
			sigs,
			'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000'
		);

		UserOperation[] memory tmp1 = new UserOperation[](1);
		tmp1[0] = tmp;

		entryPoint.handleOps(tmp1, payable(alice));

		// Transfer has been made, nonce incremented, used nonce set
		assertTrue(address(alice).balance == 1.5 ether);
		assertTrue(address(safe).balance == 0.5 ether);
		assertTrue(forumSafeModule.nonce() == 1);
		//assertTrue(forumSafeModule.usedNonces(entryPoint.getUserOpHash(tmp)) == 1);
	}

	// function testManageAdminViaEntryPoint() public {
	// 	// check balance before
	// 	assertTrue(forumSafeModule.memberVoteThreshold() == 50);

	// 	// build a proposal
	// 	bytes memory manageAdminCalldata = buildManageAdminPayload(
	// 		IForumSafeModuleTypes.ProposalType.MEMBER_THRESHOLD,
	// 		[address(0)],
	// 		[uint256(60)],
	// 		[new bytes(0)]
	// 	);

	// 	// build user operation
	// 	UserOperation memory tmp = buildUserOp(forumSafeModule, manageAdminCalldata, alicePk);

	// 	UserOperation[] memory tmp1 = new UserOperation[](1);
	// 	tmp1[0] = tmp;

	// 	entryPoint.handleOps(tmp1, payable(alice));

	// 	assertTrue(forumSafeModule.memberVoteThreshold() == 60);
	// }
}
