// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable no-console */

// import './helpers/ForumSafeTestConfig.t.sol';
import './config/ERC4337TestConfig.t.sol';

import {SignatureHelper} from './config/SignatureHelper.t.sol';

import {Base64} from '@libraries/Base64.sol';

contract Module4337Test is ERC4337TestConfig, SignatureHelper {
	ForumGroupModule private forumSafeModule;
	GnosisSafe private safe;

	// Some public keys used as signers in tests
	uint256[2] internal publicKey;
	uint256[2] internal publicKey2;
	uint256[] internal membersX;
	uint256[] internal membersY;

	string internal constant SALT_1 = '1';
	string internal constant SALT_2 = '2';

	bytes internal basicTransferCalldata;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Create passkey signers
		publicKey = createPublicKey(SALT_1);
		publicKey2 = createPublicKey(SALT_2);

		// Format signers into arrays to be added to contract
		membersX.push(publicKey[0]);
		membersY.push(publicKey[1]);

		(
			// Deploy a forum safe from the factory
			forumSafeModule,
			safe
		) = forumGroupFactory.deployForumGroup('test', 5000, membersX, membersY);

		// Deal the account some funds
		vm.deal(address(safe), 1 ether);

		// Build a basic transaction to execute in some tests
		basicTransferCalldata = buildExecutionPayload(
			alice,
			uint256(0.5 ether),
			new bytes(0),
			Enum.Operation.Call
		);
	}

	/// -----------------------------------------------------------------------
	/// SETUP AND FUNCTION TESTS
	/// -----------------------------------------------------------------------

	function testSetupGroup() public {
		// check the members and threshold are set
		uint256[2][] memory members = forumSafeModule.getMembers();

		forumSafeModule.setUp(forumSafeModule, 5000, membersX, membersY);

		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(forumSafeModule.voteThreshold() == 5000);
	}

	function testUpdateThreshold(uint256 threshold) public {
		vm.assume(threshold > 0 && threshold <= 10000);
		assertTrue(forumSafeModule.voteThreshold() == 5000);

		vm.prank(entryPointAddress);
		forumSafeModule.setThreshold(threshold);

		assertTrue(forumSafeModule.voteThreshold() == threshold);
	}

	function testAddMember() public {
		assertTrue(forumSafeModule.getMembers().length == 1);

		vm.prank(entryPointAddress);
		forumSafeModule.addMember(publicKey2[0], publicKey2[1]);

		uint256[2][] memory members = forumSafeModule.getMembers();

		assertTrue(members[1][0] == publicKey2[0]);
		assertTrue(members[1][1] == publicKey2[1]);
		assertTrue(forumSafeModule.getMembers().length == 2);
	}

	/// -----------------------------------------------------------------------
	/// EXECUTION TESTS
	/// -----------------------------------------------------------------------

	function testExecutionViaEntryPoint() public {
		// check balance before
		assertTrue(address(alice).balance == 1 ether);
		assertTrue(address(safe).balance == 1 ether);
		// assertTrue(forumSafeModule.nonce() == 0);

		// Build user operation
		UserOperation memory tmp = buildUserOp(
			address(forumSafeModule),
			safe.nonce(),
			new bytes(0),
			basicTransferCalldata
		);

		// Get signatures for the user operation
		uint256[2] memory s1 = signMessageForPublicKey(
			SALT_1,
			Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(tmp)))
		);

		// @dev signatures must be in the order members are added to the group (can be retrieved using getMembers())
		uint256[2][] memory sigs = new uint256[2][](1);
		sigs[0] = s1;

		tmp.signature = abi.encode(sigs, authentacatorData);

		UserOperation[] memory tmp1 = new UserOperation[](1);
		tmp1[0] = tmp;

		entryPoint.handleOps(tmp1, payable(alice));

		// Transfer has been made, nonce incremented, used nonce set
		assertTrue(address(alice).balance == 1.5 ether);
		assertTrue(address(safe).balance == 0.5 ether);
		assertTrue(safe.nonce() == 1);
		//assertTrue(forumSafeModule.usedNonces(entryPoint.getUserOpHash(tmp)) == 1);
	}

	function testVotingWithEmptySig() public {
		// Add second member to make  agroup of 2
		membersX.push(publicKey2[0]);
		membersY.push(publicKey2[1]);

		(
			// Deploy a forum safe from the factory with 2 signers
			forumSafeModule,
			safe
		) = forumGroupFactory.deployForumGroup('test2', 5000, membersX, membersY);

		deal(address(forumSafeModule), 10 ether);

		// Build user operation
		UserOperation memory tmp = buildUserOp(
			address(forumSafeModule),
			safe.nonce(),
			new bytes(0),
			basicTransferCalldata
		);

		// Get signatures for the user operation
		uint256[2] memory s1 = signMessageForPublicKey(
			SALT_1,
			Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(tmp)))
		);
		uint256[2] memory s2 = [uint256(0), uint256(0)];

		uint256[2][] memory sigs = new uint256[2][](2);
		sigs[0] = s1;
		sigs[1] = s2;

		tmp.signature = abi.encode(sigs, authentacatorData);

		UserOperation[] memory tmp1 = new UserOperation[](1);
		tmp1[0] = tmp;

		entryPoint.handleOps(tmp1, payable(address(this)));

		uint256 gas = calculateGas(tmp);

		// Transfer has been made, nonce incremented, used nonce set
		assertTrue(address(alice).balance == 1.5 ether);
		assertTrue(address(safe).balance == 0.5 ether);
		assertTrue(safe.nonce() == 1);
	}

	// test fail for below threshold
	function testRevertsIfUnderThreshold() public {
		// check balance before
		assertTrue(address(alice).balance == 1 ether);
		assertTrue(address(safe).balance == 1 ether);
		assertTrue(safe.nonce() == 0);

		//Add second member to make  agroup of 2
		membersX.push(publicKey2[0]);
		membersY.push(publicKey2[1]);

		(
			// Deploy a forum safe from the factory with 2 signers, over 50% threshold
			forumSafeModule,
			safe
		) = forumGroupFactory.deployForumGroup('test2', 5001, membersX, membersY);

		deal(address(forumSafeModule), 10 ether);

		// Build user operation
		UserOperation memory tmp = buildUserOp(
			address(forumSafeModule),
			safe.nonce(),
			new bytes(0),
			basicTransferCalldata
		);

		// Get signatures for the user operation
		uint256[2] memory s1 = signMessageForPublicKey(
			SALT_1,
			Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(tmp)))
		);
		// Empty as member 2 did not vote
		uint256[2] memory s2 = [uint256(0), uint256(0)];

		uint256[2][] memory sigs = new uint256[2][](2);
		sigs[0] = s1;
		sigs[1] = s2;

		tmp.signature = abi.encode(sigs, authentacatorData);

		UserOperation[] memory tmp1 = new UserOperation[](1);
		tmp1[0] = tmp;

		// Revert as not enough votes
		vm.expectRevert(bytes('FailedOp(0, AA24 signature error)'));
		entryPoint.handleOps(tmp1, payable(address(this)));

		// Transfer has not been made, balances and nonce unchanged
		assertTrue(address(alice).balance == 1 ether);
		assertTrue(address(safe).balance == 1 ether);
		assertTrue(safe.nonce() == 0);
	}

	// prevent sig reuse

	receive() external payable {}
}
