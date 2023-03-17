// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable no-console */

import './config/ERC4337TestConfig.t.sol';

import {SignatureHelper} from './config/SignatureHelper.t.sol';

import {Base64} from '@libraries/Base64.sol';

/**
 * TODO
 * - Improve salt for group deployment. Should be more restrictive to prevent frontrunning, and should work cross chain
 * - Improve test code - still some repeated code that could be broken into functions
 */
contract ForumGroupTest is ERC4337TestConfig, SignatureHelper {
	ForumGroup private forumGroup;
	GnosisSafe private safe;

	// Some public keys used as signers in tests
	uint256[2] internal publicKey;
	uint256[2] internal publicKey2;
	uint256[] internal membersX;
	uint256[] internal membersY;

	string internal constant SIGNER_1 = '1';
	string internal constant SIGNER_2 = '2';

	string internal constant GROUP_NAME_1 = 'test';
	string internal constant GROUP_NAME_2 = 'test2';

	bytes internal basicTransferCalldata;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Create passkey signers
		publicKey = createPublicKey(SIGNER_1);
		publicKey2 = createPublicKey(SIGNER_2);

		// Format signers into arrays to be added to contract
		membersX.push(publicKey[0]);
		membersY.push(publicKey[1]);

		// Deploy a forum safe from the factory
		forumGroup = ForumGroup(
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_1, 1, membersX, membersY))
		);

		// Deal the account some funds
		vm.deal(address(forumGroup), 1 ether);

		// Build a basic transaction to execute in some tests
		basicTransferCalldata = buildExecutionPayload(
			alice,
			uint256(0.5 ether),
			new bytes(0),
			Enum.Operation.Call
		);
	}

	/// -----------------------------------------------------------------------
	/// SETUP TESTS
	/// -----------------------------------------------------------------------

	function testSetupGroup() public {
		// Check the members and threshold are set
		uint256[2][] memory members = forumGroup.getMembers();

		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(forumGroup.getVoteThreshold() == 1);
		assertTrue(forumGroup.entryPoint() == address(entryPoint));

		// The safe has been initialized with a threshold of 1
		// This threshold is not used when executing via entrypoint
		assertTrue(forumGroup.getVoteThreshold() == 1);
	}

	function testDeployViaEntryPoint() public {
		// Encode the calldata for the factory to create an account
		bytes memory factoryCalldata = abi.encodeCall(
			forumGroupFactory.deployForumGroup,
			(GROUP_NAME_2, 1, membersX, membersY)
		);

		//Prepend the address of the factory
		bytes memory initCode = abi.encodePacked(address(forumGroupFactory), factoryCalldata);

		// Calculate address in advance to use as sender
		address preCalculatedAccountAddress = forumGroupFactory.getAddress(
			keccak256(abi.encode(GROUP_NAME_2))
		);

		// Deal funds to account
		deal(preCalculatedAccountAddress, 1 ether);
		// Cast to ERC4337Account - used to make some test assertions easier
		ForumGroup newForumGroup = ForumGroup(payable(preCalculatedAccountAddress));

		// Build user operation
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = buildUserOp(preCalculatedAccountAddress, 0, initCode, basicTransferCalldata);

		// Get signature for userOp
		uint256[2][] memory sigs = new uint256[2][](2);
		sigs[0] = signMessageForPublicKey(
			SIGNER_1,
			Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOps[0])))
		);
		userOps[0].signature = abi.encode(sigs, authentacatorData);

		// Handle userOp
		entryPoint.handleOps(userOps, payable(alice));

		// Check the account has been deployed
		// check the members and threshold are set
		uint256[2][] memory members = newForumGroup.getMembers();

		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(newForumGroup.getVoteThreshold() == 1);
		assertTrue(newForumGroup.entryPoint() == address(entryPoint));
	}

	/// -----------------------------------------------------------------------
	/// FUNCTION TESTS
	/// -----------------------------------------------------------------------

	function testGetAddress() public {
		// Get address should predict correct deployed address
		assertTrue(
			forumGroupFactory.getAddress(keccak256(abi.encode(GROUP_NAME_1))) == address(forumGroup)
		);
	}

	function testReturnAddressIfAlreadyDeployed() public {
		// Deploy a second forum safe with the same name
		ForumGroup newForumGroup = ForumGroup(
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_1, 1, membersX, membersY))
		);

		// Get address should return the address of the first safe
		assertTrue(address(newForumGroup) == address(forumGroup));
	}

	function testUpdateThreshold(uint256 threshold) public {
		assertTrue(forumGroup.getVoteThreshold() == 1);

		// Add a member so we can change threshold from 1-> 2 later
		vm.prank(address(forumGroup));
		forumGroup.addMemberWithThreshold(
			MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}),
			1
		);

		vm.startPrank(address(forumGroup));

		// Threshold must be greater than 1 and less then or equal to current member count (2)
		if (threshold > 2) {
			vm.expectRevert('MM201');
			forumGroup.changeVoteThreshold(threshold);
			threshold = 1; // fallback to default so final assertiion is correctly evaluated
		} else {
			if (threshold < 1) {
				vm.expectRevert('MM202');
				forumGroup.changeVoteThreshold(threshold);
				threshold = 1; // fallback to default so final assertiion is correctly evaluated
			} else {
				forumGroup.changeVoteThreshold(threshold);
			}
		}

		assertTrue(forumGroup.getVoteThreshold() == threshold);
	}

	function testAddMemberWithThreshold() public {
		assertTrue(forumGroup.getMembers().length == 1);

		vm.prank(address(forumGroup));
		forumGroup.addMemberWithThreshold(
			MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}),
			2
		);
		uint256[2][] memory members = forumGroup.getMembers();

		assertTrue(members[0][0] == publicKey2[0]);
		assertTrue(members[0][1] == publicKey2[1]);

		assertTrue(forumGroup.getMembers().length == 2);
	}

	function testRemoveMember() public {
		// Add a member so we can change threshold from 1-> 2 later
		vm.prank(address(forumGroup));
		forumGroup.addMemberWithThreshold(
			MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}),
			2
		);

		// Get initial members
		uint256[2][] memory members = forumGroup.getMembers();

		assertTrue(members.length == 2);
		assertTrue(forumGroup.getVoteThreshold() == 2);

		MemberManager.Member memory prev = MemberManager.Member({
			x: publicKey2[0],
			y: publicKey2[1]
		});

		MemberManager.Member memory removee = MemberManager.Member({
			x: publicKey[0],
			y: publicKey[1]
		});

		vm.prank(address(forumGroup));
		forumGroup.removeMember(prev, removee, 1);

		members = forumGroup.getMembers();

		// Length is 1, pk2 remains, pk is removed, threshold is updated
		assertTrue(members.length == 1);
		assertTrue(members[0][0] == publicKey2[0]);
		assertTrue(members[0][1] == publicKey2[1]);
		assertTrue(forumGroup.getVoteThreshold() == 1);
	}

	function testUpdateEntryPoint() public {
		assertTrue(forumGroup.entryPoint() == address(entryPoint));

		// Reverts if not called by entrypoint
		vm.expectRevert(ForumGroup.NotFromEntrypoint.selector);
		forumGroup.setEntryPoint(address(this));

		vm.prank(address(entryPoint));
		forumGroup.setEntryPoint(address(this));

		assertTrue(forumGroup.entryPoint() == address(this));
	}

	/// -----------------------------------------------------------------------
	/// EXECUTION TESTS
	/// -----------------------------------------------------------------------

	function testExecutionViaEntryPoint() public {
		// check balance before
		assertTrue(address(alice).balance == 1 ether);
		assertTrue(address(forumGroup).balance == 1 ether);
		assertTrue(forumGroup.nonce() == 0);

		// Build user operation
		UserOperation memory tmp = buildUserOp(
			address(forumGroup),
			forumGroup.nonce(),
			new bytes(0),
			basicTransferCalldata
		);

		// Get signatures for the user operation
		uint256[2] memory s1 = signMessageForPublicKey(
			SIGNER_1,
			Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(tmp)))
		);

		// @dev signatures must be in the order members are added to the group (can be retrieved using getMembers())
		uint256[2][] memory sigs = new uint256[2][](1);
		sigs[0] = s1;

		tmp.signature = abi.encode(sigs, authentacatorData);

		UserOperation[] memory tmp1 = new UserOperation[](1);
		tmp1[0] = tmp;

		entryPoint.handleOps(tmp1, payable(bob));

		// ! correct gas cost - take it from the useroperation event
		uint256 gas = calculateGas(tmp);

		// Transfer has been made, nonce incremented, used nonce set
		assertTrue(address(alice).balance == 1.5 ether);
		assertTrue(address(forumGroup).balance == 0.5 ether - gas);
		assertTrue(forumGroup.nonce() == 1);
		assertTrue(forumGroup.usedNonces(tmp.nonce) == 1);
	}

	function testVotingWithEmptySig() public {
		// Add second member to make a group of 2
		membersX.push(publicKey2[0]);
		membersY.push(publicKey2[1]);

		forumGroup = ForumGroup(
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_2, 1, membersX, membersY))
		);

		deal(address(forumGroup), 10 ether);

		// Build user operation
		UserOperation memory tmp = buildUserOp(
			address(forumGroup),
			forumGroup.nonce(),
			new bytes(0),
			basicTransferCalldata
		);

		// Get signatures for the user operation
		uint256[2] memory s1 = signMessageForPublicKey(
			SIGNER_1,
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
		assertTrue(address(forumGroup).balance == 0.5 ether - gas);
		assertTrue(forumGroup.nonce() == 1);
		assertTrue(forumGroup.usedNonces(tmp.nonce) == 1);
	}

	function testRevertsIfUnderThreshold() public {
		//Add second member to make  agroup of 2
		membersX.push(publicKey2[0]);
		membersY.push(publicKey2[1]);

		// Deploy a forum safe from the factory with 2 signers and threshold 2
		forumGroup = ForumGroup(
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_2, 2, membersX, membersY))
		);

		deal(address(forumGroup), 10 ether);

		// Build user operation
		UserOperation memory tmp = buildUserOp(
			address(forumGroup),
			forumGroup.nonce(),
			new bytes(0),
			basicTransferCalldata
		);

		// Get signatures for the user operation
		uint256[2] memory s1 = signMessageForPublicKey(
			SIGNER_1,
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
		vm.expectRevert('FailedOp(0, AA24 signature error)');
		entryPoint.handleOps(tmp1, payable(address(this)));

		// Transfer has not been made, balances and nonce unchanged
		assertTrue(address(alice).balance == 1 ether);
		assertTrue(address(forumGroup).balance == 10 ether);
		assertTrue(forumGroup.nonce() == 0);
	}

	receive() external payable {}
}
