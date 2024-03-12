// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./ForumAccount.base.t.sol";

contract ForumAccountTestIntegrations is ForumAccountTestBase {
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
    /// Execution tests
    /// -----------------------------------------------------------------------

    // ! consider a limit to prevent changing entrypoint to a contract that is not compatible with 4337
    function testUpdateEntryPoint() public {
        // Check old entry point is set
        assertEq(address(forumAccount.entryPoint()), entryPointAddress, "entry point not set");

        // Build userop to set entrypoint to this contract as a test
        UserOperation memory userOp = buildUserOp(
            forumAccountAddress,
            entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY),
            "",
            abi.encodeWithSignature("setEntryPoint(address)", address(this))
        );

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Handle userOp
        entryPoint.handleOps(userOps, payable(this));

        // Check that the entry point has been updated
        assertEq(address(forumAccount.entryPoint()), address(this), "entry point not updated");
    }

    function testAccountTransfer() public {
        // Build user operation
        UserOperation memory userOp = buildUserOp(forumAccountAddress, 0, "", basicTransferCalldata);

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Check nonce before tx
        assertEq(entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY), 0, "nonce not correct");

        // Handle userOp
        entryPoint.handleOps(userOps, payable(address(this)));

        uint256 gas = calculateGas(userOp);

        // Check updated balances
        assertEq(forumAccountAddress.balance, 0.5 ether - gas, "balance not updated");
        assertEq(alice.balance, INITIAL_BALANCE + 0.5 ether, "balance not updated");

        // Check account nonce
        assertEq(entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY), 1, "nonce not updated");
    }

    // Simulates adding an EOA owner to the safe (can act as a guardian in case of loss)
    function testAccountAddOwner() public {
        // Build payload to enable a module
        bytes memory addOwnerPayload =
            abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", address(this), 1);

        bytes memory payload = buildExecutionPayload(forumAccountAddress, 0, addOwnerPayload, Enum.Operation.Call);

        // Build user operation
        UserOperation memory userOp =
            buildUserOp(forumAccountAddress, entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY), "", payload);

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Check nonce before tx
        assertEq(entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY), 0, "nonce not correct");

        // Handle userOp
        entryPoint.handleOps(userOps, payable(address(this)));

        uint256 gas = calculateGas(userOp);

        // Check updated balances
        assertEq(forumAccountAddress.balance, 1 ether - gas, "balance not updated");
        // Check account nonce
        assertEq(entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY), 1, "nonce not updated");
        // Check module is enabled
        assertTrue(forumAccount.isOwner(address(this)), "owner not added");
    }

    // ! Double check with new validation including the domain seperator
    function testCannotReplaySig() public {
        // Build user operation
        UserOperation memory userOp = buildUserOp(forumAccountAddress, 0, "", basicTransferCalldata);

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Check nonce before tx
        assertEq(entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY), 0, "nonce not correct");

        // Handle first userOp
        entryPoint.handleOps(userOps, payable(address(this)));

        assertEq(entryPoint.getNonce(forumAccountAddress, BASE_NONCE_KEY), 1, "nonce not correct");

        vm.expectRevert();
        entryPoint.handleOps(userOps, payable(address(this)));
    }

    function testAddAndRemoveGuardian() public {
        address[] memory owners = forumAccount.getOwners();
        assertEq(owners.length, 1, "should start with 1 owner");

        vm.startPrank(forumAccountAddress);

        // Simulate adding an owner
        forumAccount.addOwnerWithThreshold(address(this), 1);

        owners = forumAccount.getOwners();
        assertEq(owners.length, 2, "owner not added");
        assertEq(owners[0], address(this), "incorrect owner");

        // Simulate swapping an owner (address(1) indicates sentinel owner, which is 'prev' in linked list)
        forumAccount.swapOwner(address(1), address(this), alice);

        owners = forumAccount.getOwners();
        assertEq(owners.length, 2, "incorrect number of owners");
        assertEq(owners[0], alice, "incorrect owner");

        // Simulate removing an owner
        forumAccount.removeOwner(address(1), alice, 1);

        owners = forumAccount.getOwners();
        assertEq(owners.length, 1, "owner not removed");
        assertEq(owners[0], address(0xdead), "incorrect owner");
    }
}
