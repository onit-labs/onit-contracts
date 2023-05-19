// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./ForumAccount.base.t.sol";

contract ForumAccountTestSetup is ForumAccountTestBase {
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
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testSetUpState() public {
        // Check 4337 singelton is set in factory (base implementation for Forum 4337 accounts)
        assertEq(
            address(forumAccountFactory.forumAccountSingleton()),
            address(forumAccountSingleton),
            "forumAccountSingleton not set"
        );
        // Check 4337 entryPoint is set in factory
        assertEq(forumAccountFactory.entryPoint(), entryPointAddress, "entryPoint not set");
        // Check 4337 gnosis fallback handler is set in factory
        assertEq(address(forumAccountFactory.gnosisFallbackLibrary()), address(handler), "handler not set");
        // Can not initialize the singleton
        vm.expectRevert("GS200");
        forumAccountSingleton.initialize(entryPointAddress, publicKey, address(1), "", "", "");
    }

    /// -----------------------------------------------------------------------
    /// Deployment tests
    /// -----------------------------------------------------------------------

    function testFactoryCreateAccount() public {
        // Check that the account from setup is deployed and data is set on account, and safe
        assertEq(forumAccount.owner()[0], publicKey[0], "owner not set");
        assertEq(forumAccount.owner()[1], publicKey[1], "owner not set");
        assertEq(forumAccount.getThreshold(), 1, "threshold not set");
        assertEq(forumAccount.getOwners()[0], address(0xdead), "owner not set on safe");
        assertEq(address(forumAccount.entryPoint()), address(entryPoint), "entry point not set");

        // Can not initialize the same account twice
        vm.expectRevert("GS200");
        forumAccount.initialize(entryPointAddress, publicKey, address(1), "", "", "");
    }

    function testFactoryDeployFromEntryPoint() public {
        //Encode the calldata for the factory to create an account
        bytes memory factoryCalldata = abi.encodeWithSignature("createForumAccount(uint256[2])", publicKey2);

        //Prepend the address of the factory
        bytes memory initCode = abi.encodePacked(address(forumAccountFactory), factoryCalldata);

        // Calculate address in advance to use as sender
        address preCalculatedAccountAddress = (forumAccountFactory).getAddress(accountSalt(publicKey2));
        // Deal funds to account
        deal(preCalculatedAccountAddress, 1 ether);
        // Cast to ForumAccount - used to make some test assertions easier
        ForumAccount testNew4337Account = ForumAccount(payable(preCalculatedAccountAddress));

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(
            buildUserOp(preCalculatedAccountAddress, 0, initCode, basicTransferCalldata), SIGNER_2
        );

        // Handle userOp
        entryPoint.handleOps(userOps, payable(alice));

        // Check that the account is deployed and data is set on account, and safe
        assertEq(testNew4337Account.owner()[0], publicKey2[0], "owner not set");
        assertEq(testNew4337Account.owner()[1], publicKey2[1], "owner not set");
        assertEq(testNew4337Account.getThreshold(), 1, "threshold not set");
        assertEq(testNew4337Account.getOwners()[0], address(0xdead), "owner not set on safe");
        assertEq(address(testNew4337Account.entryPoint()), entryPointAddress, "entry point not set");
    }

    function testCorrectAddressCrossChain() public {
        address tmpMumbai;
        address tmpFuji;

        // Fork Mumbai and create an account from a fcatory
        vm.createSelectFork(vm.envString("MUMBAI_RPC_URL"));

        forumAccountFactory = new ForumAccountFactory(
    		forumAccountSingleton,
    		entryPointAddress, 
    		address(handler),
    		'',
    '',
    ''
    	);

        // Deploy an account to be used in tests
        tmpMumbai = forumAccountFactory.createForumAccount(publicKey);

        // Fork Fuji and create an account from a fcatory
        vm.createSelectFork(vm.envString("FUJI_RPC_URL"));

        forumAccountFactory = new ForumAccountFactory(
    		forumAccountSingleton,
    		entryPointAddress,
    		address(handler),
    		'',
    '',
    ''
    	);

        // Deploy an account to be used in tests
        tmpFuji = forumAccountFactory.createForumAccount(publicKey);

        assertEq(tmpMumbai, tmpFuji, "address not the same");
    }
}
