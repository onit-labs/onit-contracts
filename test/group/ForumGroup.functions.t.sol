// SPDX-License-Identifier: GPL-3.0-or-latersol
pragma solidity ^0.8.15;

import "./ForumGroup.base.t.sol";

contract ForumGroupTestFunctions is ForumGroupTestBase {
    /// -----------------------------------------------------------------------
    /// SETUP
    /// -----------------------------------------------------------------------

    function setUp() public {
        // Create passkey signers
        publicKey = createPublicKey(SIGNER_1);
        publicKey2 = createPublicKey(SIGNER_2);

        // Format signers into arrays to be added to contract
        inputMembers.push([publicKey[0], publicKey[1]]);

        // Deploy a forum safe from the factory
        forumGroup = ForumGroup(payable(forumGroupFactory.createForumGroup(GROUP_NAME_1, 1, inputMembers)));
        forumGroupAddress = address(forumGroup);

        // Deal the account some funds
        vm.deal(forumGroupAddress, 1 ether);

        // Build a basic transaction to execute in some tests
        basicTransferCalldata = buildExecutionPayload(alice, uint256(0.5 ether), "", Enum.Operation.Call);
    }

    /// -----------------------------------------------------------------------
    /// FUNCTION TESTS
    /// -----------------------------------------------------------------------

    function testGetAddress() public {
        // Get address should predict correct deployed address
        assertTrue(forumGroupFactory.getAddress(keccak256(abi.encodePacked(GROUP_NAME_1))) == forumGroupAddress);
    }

    function testReturnAddressIfAlreadyDeployed() public {
        // Deploy a second forum safe with the same name
        ForumGroup newForumGroup =
            ForumGroup(payable(forumGroupFactory.createForumGroup(GROUP_NAME_1, 1, inputMembers)));

        // Get address should return the address of the first safe
        assertTrue(address(newForumGroup) == forumGroupAddress);
    }

    function testAddMemberWithThreshold() public {
        assertTrue(forumGroup.getMembers().length == 1);

        vm.prank(forumGroupAddress);
        forumGroup.addMemberWithThreshold(MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}), 2);
        uint256[2][] memory members = forumGroup.getMembers();

        assertTrue(members[0][0] == publicKey[0]);
        assertTrue(members[0][1] == publicKey[1]);
        assertTrue(members[1][0] == publicKey2[0]);
        assertTrue(members[1][1] == publicKey2[1]);
        assertTrue(forumGroup.getVoteThreshold() == 2);

        // Check the member has been minted a membership token
        assertTrue(forumGroup.isMember(publicKeyAddress(publicKey2)) == 1);

        assertTrue(forumGroup.getMembers().length == 2);
    }

    function testCannotAddMemberWithThresholdIncorrectly() public {
        uint256[2][] memory members = forumGroup.getMembers();
        assertTrue(members.length == 1);

        vm.startPrank(forumGroupAddress);

        vm.expectRevert(MemberManager.InvalidThreshold.selector);
        forumGroup.addMemberWithThreshold(MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}), 0);

        vm.expectRevert(MemberManager.InvalidThreshold.selector);
        forumGroup.addMemberWithThreshold(MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}), 3);

        vm.expectRevert(MemberManager.MemberExists.selector);
        forumGroup.addMemberWithThreshold(MemberManager.Member({x: publicKey[0], y: publicKey[1]}), 3);

        members = forumGroup.getMembers();
        assertTrue(members.length == 1);
    }

    function testRemoveMemberWithThreshold() public {
        // Add a member so we can change threshold from 1-> 2 later
        vm.prank(forumGroupAddress);
        forumGroup.addMemberWithThreshold(MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}), 2);

        // Get initial members
        uint256[2][] memory members = forumGroup.getMembers();

        assertTrue(members.length == 2);
        assertTrue(forumGroup.getVoteThreshold() == 2);

        vm.prank(forumGroupAddress);
        forumGroup.removeMemberWithThreshold(publicKeyAddress(publicKey2), 1);

        members = forumGroup.getMembers();
        assertTrue(members.length == 1);
        assertTrue(forumGroup.getVoteThreshold() == 1);
        assertTrue(forumGroup.isMember(publicKeyAddress(publicKey2)) == 0);
    }

    function testCannotRemoveMemberWithThresholdIncorrectly() public {
        vm.startPrank(forumGroupAddress);

        vm.expectRevert(MemberManager.CannotRemoveMember.selector);
        forumGroup.removeMemberWithThreshold(publicKeyAddress(publicKey2), 1);

        // Add a member so we can change threshold from 1-> 2 later
        forumGroup.addMemberWithThreshold(MemberManager.Member({x: publicKey2[0], y: publicKey2[1]}), 2);

        vm.expectRevert(MemberManager.InvalidThreshold.selector);
        forumGroup.removeMemberWithThreshold(publicKeyAddress(publicKey2), 0);

        vm.expectRevert(MemberManager.InvalidThreshold.selector);
        forumGroup.removeMemberWithThreshold(publicKeyAddress(publicKey2), 3);

        // Remove member so we can check the restriction on removing the final memebr next
        forumGroup.removeMemberWithThreshold(publicKeyAddress(publicKey2), 1);

        vm.expectRevert(MemberManager.InvalidThreshold.selector);
        forumGroup.removeMemberWithThreshold(publicKeyAddress(publicKey), 1);
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

    function testValidateUserOpGroup() public {
        // Build user operation
        UserOperation memory userOp = buildUserOp(forumGroupAddress, 0, "", basicTransferCalldata);
        UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, "");

        vm.startPrank(entryPointAddress);
        assertEq(
            forumGroup.validateUserOp(userOpArray[0], entryPoint.getUserOpHash(userOp), 0),
            0,
            "validateUserOp should return 0"
        );

        vm.stopPrank();
    }

    function testCannotDuplicateVote() public {
        // Add second signer to group
        inputMembers.push([publicKey2[0], publicKey2[1]]);

        // Deploy a forum safe from the factory with 2 signers and threshold 2
        ForumGroup forumGroupLocalTest =
            ForumGroup(payable(forumGroupFactory.createForumGroup(GROUP_NAME_2, 2, inputMembers)));

        // Build user operation
        UserOperation memory userOp = buildUserOp(address(forumGroupLocalTest), 0, "", basicTransferCalldata);

        uint256[2] memory singleSig =
            signMessageForPublicKey(SIGNER_1, Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))));

        // Simulate a user doubling their sig for this prop
        bytes memory badDoubledSig = abi.encodePacked(singleSig[0], singleSig[1], singleSig[0], singleSig[1]);

        // Simulate a user trying to pass singer info that would take their vote twice
        uint256 badSignerIndex = uint8(2);

        userOp.signature = abi.encodePacked(badSignerIndex, badDoubledSig);

        bytes32 userOpHash = entryPoint.getUserOpHash(userOp);

        vm.startPrank(entryPointAddress);
        vm.expectRevert(ForumGroup.InvalidSigner.selector);
        forumGroupLocalTest.validateUserOp(userOp, userOpHash, 0);
        vm.stopPrank();
    }

    function testMaximumMemberCountValidation() public {
        // Create x,y public keys for signers
        uint256[2] memory publicKey3 = createPublicKey("3");
        uint256[2] memory publicKey4 = createPublicKey("4");
        uint256[2] memory publicKey5 = createPublicKey("5");
        uint256[2] memory publicKey6 = createPublicKey("6");
        uint256[2] memory publicKey7 = createPublicKey("7");

        delete inputMembers;

        // Add members to make a large group
        inputMembers.push([publicKey[0], publicKey[1]]);
        inputMembers.push([publicKey2[0], publicKey2[1]]);
        inputMembers.push([publicKey3[0], publicKey3[1]]);
        inputMembers.push([publicKey4[0], publicKey4[1]]);
        inputMembers.push([publicKey5[0], publicKey5[1]]);
        inputMembers.push([publicKey6[0], publicKey6[1]]);
        inputMembers.push([publicKey7[0], publicKey7[1]]);

        // Deploy a forum safe from the factory with many signers and threshold 2
        ForumGroup forumGroupLocalTest =
            ForumGroup(payable(forumGroupFactory.createForumGroup(GROUP_NAME_2, 2, inputMembers)));

        // Build user operation
        UserOperation memory userOp = buildUserOp(address(forumGroupLocalTest), 0, "", basicTransferCalldata);

        vm.startPrank(entryPointAddress);

        uint256 gas;

        uint256 encodedSignerInfo;

        bytes memory workingSigs;

        // Loop and add a signature each time
        for (uint256 i = 0; i < 10; i++) {
            uint256[2] memory currentSig =
                signMessageForPublicKey(uint2str(i + 1), Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))));

            workingSigs = abi.encodePacked(workingSigs, abi.encodePacked(currentSig[0], currentSig[1]));

            // Replace the lowest 8 bits with the new number of signers (i+1)
            encodedSignerInfo = (encodedSignerInfo & ~uint256(0xff)) | uint8(i + 1);
            // Then ass the new signer index (i) shifted left
            encodedSignerInfo |= uint256(i) << (8 * (i + 1));

            userOp.signature = abi.encode(encodedSignerInfo);
            userOp.signature = abi.encodePacked(userOp.signature, workingSigs);

            gas = gasleft();
            forumGroupLocalTest.validateUserOp(userOp, entryPoint.getUserOpHash(userOp), 0);
            gas -= gasleft();

            if (gas > 1500000) {
                console.log("Gas used: ", gas, " with ", i);
                break;
            }
        }

        vm.stopPrank();

        delete inputMembers;
    }
}
