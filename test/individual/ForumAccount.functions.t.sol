// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./ForumAccount.base.t.sol";

contract ForumAccountTestFunctions is ForumAccountTestBase {
    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public {
        publicKey = createPublicKey(SIGNER_1);
        publicKey2 = createPublicKey(SIGNER_2);

        // Deploy an account to be used in tests later
        forumAccountAddress = forumAccountFactory.createForumAccount(publicKey);
        forumAccount = ForumAccount(forumAccountAddress);

        // Deal funds to account
        deal(forumAccountAddress, 1 ether);

        // Build a basic transaction to execute in some tests
        basicTransferCalldata = buildExecutionPayload(alice, uint256(0.5 ether), "", Enum.Operation.Call);
    }

    /// -----------------------------------------------------------------------
    /// Function tests
    /// -----------------------------------------------------------------------

    function testValidateUserOp() public {
        // Build user operation
        UserOperation memory userOp = buildUserOp(forumAccountAddress, 0, "", basicTransferCalldata);
        userOp.signature =
            abi.encode(signMessageForPublicKey(SIGNER_1, Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp)))));

        vm.startPrank(entryPointAddress);
        forumAccount.validateUserOp(userOp, entryPoint.getUserOpHash(userOp), 0);
    }

    function testOnlyEntryPoint() public {
        vm.expectRevert();
        forumAccount.validateUserOp(buildUserOp(forumAccountAddress, 0, "", basicTransferCalldata), 0, 0);

        vm.expectRevert();
        forumAccount.executeAndRevert(address(this), 0, "", Enum.Operation.Call);
    }
}
