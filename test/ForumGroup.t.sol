// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable no-console */

import './config/ERC4337TestConfig.t.sol';

import {Base64} from '@libraries/Base64.sol';

/**
 * TODO
 * - Improve salt for group deployment. Should be more restrictive to prevent frontrunning, and should work cross chain
 * - Improve test code - still some repeated code that could be broken into functions
 */
contract ForumGroupTest is ERC4337TestConfig {
	ForumGroup private forumGroup;
	Safe private safe;

	// Some public keys used as signers in tests
	uint256[2] internal publicKey;
	uint256[2] internal publicKey2;
	uint256[2][] internal inputMembers;

	string internal constant SIGNER_1 = '1';
	string internal constant SIGNER_2 = '2';

	string internal constant GROUP_NAME_1 = 'test';
	string internal constant GROUP_NAME_2 = 'test2';

	bytes internal basicTransferCalldata;

	// Token representing voting share of treasury
	uint256 internal constant TOKEN = 0;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Create passkey signers
		publicKey = createPublicKey(SIGNER_1);
		publicKey2 = createPublicKey(SIGNER_2);

		// Format signers into arrays to be added to contract
		inputMembers.push([publicKey[0], publicKey[1]]);

		// Deploy a forum safe from the factory
		forumGroup = ForumGroup(
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_1, 1, inputMembers))
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
		uint256[2][] memory members = forumGroup.getMembers();

		// Check the setup params are set correctly
		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(forumGroup.getVoteThreshold() == 1);
		assertTrue(forumGroup.entryPoint() == address(entryPoint));

		// Check the member has been minted a membership token
		assertTrue(forumGroup.isMember(publicKeyHash(publicKey)) == 1);

		// The safe has been initialized with a threshold of 1
		// This threshold is not used when executing via group
		assertTrue(forumGroup.getThreshold() == 1);
	}

	function testDeployViaEntryPoint() public {
		// Encode the calldata for the factory to create an account
		bytes memory factoryCalldata = abi.encodeCall(
			forumGroupFactory.deployForumGroup,
			(GROUP_NAME_2, 1, inputMembers)
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
		UserOperation memory userOp = buildUserOp(
			preCalculatedAccountAddress,
			0,
			initCode,
			basicTransferCalldata
		);

		UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, '');

		// Handle userOp
		entryPoint.handleOps(userOpArray, payable(alice));

		uint256[2][] memory members = newForumGroup.getMembers();

		// Check the setup params are set correctly
		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(newForumGroup.getVoteThreshold() == 1);
		assertTrue(newForumGroup.entryPoint() == address(entryPoint));

		// Check the member has been minted a membership token
		assertTrue(forumGroup.isMember(publicKeyHash(publicKey)) == 1);

		// The safe has been initialized with a threshold of 1
		// This threshold is not used when executing via group
		assertTrue(forumGroup.getThreshold() == 1);
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
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_1, 1, inputMembers))
		);

		// Get address should return the address of the first safe
		assertTrue(address(newForumGroup) == address(forumGroup));
	}

	// function testUpdateThreshold(uint256 threshold) public {
	// 	assertTrue(forumGroup.getVoteThreshold() == 1);

	// 	// Add a member so we can change threshold from 1-> 2 later
	// 	vm.prank(address(forumGroup));
	// 	forumGroup.addMember(publicKey2);
	// 	forumGroup.changeVoteThreshold(
	// 		2
	// 	);

	// 	vm.startPrank(address(forumGroup));

	// 	// Threshold must be greater than 1 and less then or equal to current member count (2)
	// 	if (threshold > 2) {
	// 		vm.expectRevert(forumGroup.InvalidThreshold.selector);
	// 		forumGroup.changeVoteThreshold(threshold);
	// 		threshold = 1; // fallback to default so final assertiion is correctly evaluated
	// 	} else {
	// 		if (threshold < 1) {
	// 			vm.expectRevert(forumGroup.InvalidThreshold.selector);
	// 			forumGroup.changeVoteThreshold(threshold);
	// 			threshold = 1; // fallback to default so final assertiion is correctly evaluated
	// 		} else {
	// 			forumGroup.changeVoteThreshold(threshold);
	// 		}
	// 	}

	// 	assertTrue(forumGroup.getVoteThreshold() == threshold);
	// }

	function testAddMemberWithThreshold() public {
		assertTrue(forumGroup.getMembers().length == 1);

		vm.prank(address(forumGroup));
		forumGroup.addMemberWithThreshold(
			ForumGroup.Member({x: publicKey2[0], y: publicKey2[1]}),
			2
		);
		uint256[2][] memory members = forumGroup.getMembers();

		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(members[1][0] == publicKey2[0]);
		assertTrue(members[1][1] == publicKey2[1]);
		assertTrue(forumGroup.getVoteThreshold() == 2);

		// Check the member has been minted a membership token
		assertTrue(forumGroup.isMember(publicKeyHash(publicKey2)) == 1);

		assertTrue(forumGroup.getMembers().length == 2);
	}

	function testCannotAddMemberWithThresholdIncorrectly() public {
		uint256[2][] memory members = forumGroup.getMembers();
		assertTrue(members.length == 1);

		vm.startPrank(address(forumGroup));

		vm.expectRevert(ForumGroup.InvalidThreshold.selector);
		forumGroup.addMemberWithThreshold(
			ForumGroup.Member({x: publicKey2[0], y: publicKey2[1]}),
			0
		);

		vm.expectRevert(ForumGroup.InvalidThreshold.selector);
		forumGroup.addMemberWithThreshold(
			ForumGroup.Member({x: publicKey2[0], y: publicKey2[1]}),
			3
		);

		vm.expectRevert(ForumGroup.MemberExists.selector);
		forumGroup.addMemberWithThreshold(ForumGroup.Member({x: publicKey[0], y: publicKey[1]}), 3);

		members = forumGroup.getMembers();
		assertTrue(members.length == 1);
	}

	function testRemoveMemberWithThreshold() public {
		// Add a member so we can change threshold from 1-> 2 later
		vm.prank(address(forumGroup));
		forumGroup.addMemberWithThreshold(
			ForumGroup.Member({x: publicKey2[0], y: publicKey2[1]}),
			2
		);

		// Get initial members
		uint256[2][] memory members = forumGroup.getMembers();

		assertTrue(members.length == 2);
		assertTrue(forumGroup.getVoteThreshold() == 2);

		vm.prank(address(forumGroup));
		forumGroup.removeMemberWithThreshold(publicKeyHash(publicKey2), 1);

		members = forumGroup.getMembers();
		assertTrue(members.length == 1);
		assertTrue(forumGroup.getVoteThreshold() == 1);
		assertTrue(forumGroup.isMember(publicKeyHash(publicKey2)) == 0);
	}

	function testCannotRemoveMemberWithThresholdIncorrectly() public {
		vm.startPrank(address(forumGroup));

		vm.expectRevert(ForumGroup.CannotRemoveMember.selector);
		forumGroup.removeMemberWithThreshold(publicKeyHash(publicKey2), 1);

		// Add a member so we can change threshold from 1-> 2 later
		forumGroup.addMemberWithThreshold(
			ForumGroup.Member({x: publicKey2[0], y: publicKey2[1]}),
			2
		);

		vm.expectRevert(ForumGroup.InvalidThreshold.selector);
		forumGroup.removeMemberWithThreshold(publicKeyHash(publicKey2), 0);

		vm.expectRevert(ForumGroup.InvalidThreshold.selector);
		forumGroup.removeMemberWithThreshold(publicKeyHash(publicKey2), 3);

		// Remove member so we can check the restriction on removing the final memebr next
		forumGroup.removeMemberWithThreshold(publicKeyHash(publicKey2), 1);

		vm.expectRevert(ForumGroup.InvalidThreshold.selector);
		forumGroup.removeMemberWithThreshold(publicKeyHash(publicKey), 1);
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
		UserOperation memory userOp = buildUserOp(
			address(forumGroup),
			forumGroup.nonce(),
			new bytes(0),
			basicTransferCalldata
		);

		UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, '');

		entryPoint.handleOps(userOpArray, payable(bob));

		// ! correct gas cost - take it from the useroperation event
		uint256 gas = calculateGas(userOp);

		// Transfer has been made, nonce incremented, used nonce set
		assertTrue(address(alice).balance == 1.5 ether);
		assertTrue(address(forumGroup).balance == 0.5 ether - gas);
		assertTrue(forumGroup.nonce() == 1);
		assertTrue(forumGroup.usedNonces(userOp.nonce) == 1);
	}

	// function testRevertsIfUnderThreshold() public {
	// 	//Add second member to make  agroup of 2
	// 	inputMembers.push([publicKey2[0], publicKey2[1]]);

	// 	// Deploy a forum safe from the factory with 2 signers and threshold 2
	// 	forumGroup = ForumGroup(
	// 		payable(forumGroupFactory.deployForumGroup(GROUP_NAME_2, 2, inputMembers))
	// 	);

	// 	deal(address(forumGroup), 10 ether);

	// 	// Build user operation
	// 	UserOperation memory userOp = buildUserOp(
	// 		address(forumGroup),
	// 		forumGroup.nonce(),
	// 		new bytes(0),
	// 		basicTransferCalldata
	// 	);

	// 	UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, '');

	// 	// Revert as not enough votes
	// 	vm.expectRevert(failedOpError(uint256(0), 'AA24 signature error'));
	// 	entryPoint.handleOps(userOpArray, payable(address(this)));

	// 	// Transfer has not been made, balances and nonce unchanged
	// 	assertTrue(address(alice).balance == 1 ether);
	// 	assertTrue(address(forumGroup).balance == 10 ether);
	// 	assertTrue(forumGroup.nonce() == 0);
	// }

	// function testAuthorisedFunctionFromEntryPoint() public {
	// 	uint256[2][] memory members = forumGroup.getMembers();

	// 	// Check member before the other is added
	// 	assertTrue(members.length == 1);
	// 	assertTrue(members[0][0] == publicKey[0]);
	// 	assertTrue(members[0][1] == publicKey[1]);

	// 	// Build add member calldata
	// 	bytes memory addMemberCalldata = abi.encodeCall(
	// 		forumGroup.addMemberWithThreshold,
	// 		(MemberManager.Member(publicKey2[0], publicKey2[1]), 1)
	// 	);

	// 	// Build a basic transaction to execute in some tests
	// 	basicTransferCalldata = buildExecutionPayload(
	// 		address(forumGroup),
	// 		0,
	// 		addMemberCalldata,
	// 		Enum.Operation.Call
	// 	);

	// 	// Build user operation
	// 	UserOperation memory userOp = buildUserOp(
	// 		address(forumGroup),
	// 		forumGroup.nonce(),
	// 		new bytes(0),
	// 		basicTransferCalldata
	// 	);

	// 	UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, '');

	// 	entryPoint.handleOps(userOpArray, payable(bob));

	// 	members = forumGroup.getMembers();

	// 	// Check new member added
	// 	assertTrue(members.length == 2);
	// 	assertTrue(members[0][0] == publicKey2[0]);
	// 	assertTrue(members[0][1] == publicKey2[1]);
	// }

	/// -----------------------------------------------------------------------
	/// HELPERS
	/// -----------------------------------------------------------------------
	function publicKeyHash(uint256[2] memory publicKey_) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(publicKey_[0], publicKey_[1]));
	}

	receive() external payable {}
}
