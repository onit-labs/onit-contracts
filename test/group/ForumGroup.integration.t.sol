// SPDX-License-Identifier: GPL-3.0-or-latersol
pragma solidity ^0.8.15;

import "./ForumGroup.base.t.sol";

contract ForumGroupTestIntegrations is ForumGroupTestBase {
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
    /// EXECUTION TESTS
    /// -----------------------------------------------------------------------

    function testExecutionViaEntryPoint() public {
        // check balance before
        assertTrue(address(alice).balance == 1 ether);
        assertTrue(forumGroupAddress.balance == 1 ether);
        assertTrue(entryPoint.getNonce(forumGroupAddress, BASE_NONCE_KEY) == 0);

        // Build user operation
        UserOperation memory userOp = buildUserOp(
            forumGroupAddress, entryPoint.getNonce(forumGroupAddress, BASE_NONCE_KEY), "", basicTransferCalldata
        );

        UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, "");

        entryPoint.handleOps(userOpArray, payable(bob));

        uint256 gas = calculateGas(userOp);

        // Transfer has been made, nonce incremented, used nonce set
        assertTrue(address(alice).balance == 1.5 ether);
        assertTrue(forumGroupAddress.balance == 0.5 ether - gas);
        assertTrue(entryPoint.getNonce(forumGroupAddress, BASE_NONCE_KEY) == 1);
    }

    function testRevertsIfUnderThreshold() public {
        //Add second member to make  agroup of 2
        inputMembers.push([publicKey2[0], publicKey2[1]]);

        // Deploy a forum safe from the factory with 2 signers and threshold 2
        ForumGroup forumGroupLocalTest =
            ForumGroup(payable(forumGroupFactory.createForumGroup(GROUP_NAME_2, 2, inputMembers)));

        deal(address(forumGroupLocalTest), 10 ether);

        // Build user operation
        UserOperation memory userOp = buildUserOp(
            address(forumGroupLocalTest),
            entryPoint.getNonce(address(forumGroupLocalTest), BASE_NONCE_KEY),
            "",
            basicTransferCalldata
        );

        UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, "");

        // Revert as not enough votes
        vm.expectRevert(failedOpError(uint256(0), "AA24 signature error"));
        entryPoint.handleOps(userOpArray, payable(address(this)));

        // Transfer has not been made, balances and nonce unchanged
        assertTrue(address(alice).balance == 1 ether);
        assertTrue(address(forumGroupLocalTest).balance == 10 ether);
        assertTrue(entryPoint.getNonce(address(forumGroupLocalTest), BASE_NONCE_KEY) == 0);

        userOpArray = signAndFormatUserOp(userOp, SIGNER_1, SIGNER_2);

        // Pass if enough votes
        entryPoint.handleOps(userOpArray, payable(address(this)));

        // Transfer has been made, balances and nonce unchanged
        assertTrue(address(alice).balance == 1.5 ether);
        //assertTrue(forumGroupAddress.balance == 10 ether);
        assertTrue(entryPoint.getNonce(address(forumGroupLocalTest), BASE_NONCE_KEY) == 1);
    }

    function testAuthorisedFunctionFromEntryPoint() public {
        uint256[2][] memory members = forumGroup.getMembers();

        // Check member before the other is added
        assertTrue(members.length == 1);
        assertTrue(members[0][0] == publicKey[0]);
        assertTrue(members[0][1] == publicKey[1]);

        // Build add member calldata
        bytes memory addMemberCalldata =
            abi.encodeCall(forumGroup.addMemberWithThreshold, (MemberManager.Member(publicKey2[0], publicKey2[1]), 1));

        // Build a basic transaction to execute in some tests
        basicTransferCalldata = buildExecutionPayload(forumGroupAddress, 0, addMemberCalldata, Enum.Operation.Call);

        // Build user operation
        UserOperation memory userOp = buildUserOp(
            forumGroupAddress, entryPoint.getNonce(forumGroupAddress, BASE_NONCE_KEY), "", basicTransferCalldata
        );

        UserOperation[] memory userOpArray = signAndFormatUserOp(userOp, SIGNER_1, "");

        entryPoint.handleOps(userOpArray, payable(bob));

        members = forumGroup.getMembers();

        // Check new member added
        assertTrue(members.length == 2);
        assertTrue(members[1][0] == publicKey2[0]);
        assertTrue(members[1][1] == publicKey2[1]);
    }

    function testNonceSequence() public {
        // Build user operation 1, nonce set to 1
        UserOperation memory userOp1 = buildUserOp(forumGroupAddress, 0, "", basicTransferCalldata);
        UserOperation[] memory userOpArray1 = signAndFormatUserOp(userOp1, SIGNER_1, "");

        // Build user operation 2, nonce set to 2
        UserOperation memory userOp2 = buildUserOp(forumGroupAddress, 1, "", basicTransferCalldata);
        UserOperation[] memory userOpArray2 = signAndFormatUserOp(userOp2, SIGNER_1, "");

        // Process first userOp
        entryPoint.handleOps(userOpArray1, payable(bob));

        assertTrue(entryPoint.getNonce(forumGroupAddress, BASE_NONCE_KEY) == 1);

        // Fail to process again
        vm.expectRevert(failedOpError(uint256(0), "AA25 invalid account nonce"));
        entryPoint.handleOps(userOpArray1, payable(bob));

        // Process second userOp
        entryPoint.handleOps(userOpArray2, payable(bob));

        assertTrue(entryPoint.getNonce(forumGroupAddress, BASE_NONCE_KEY) == 2);
    }
}
