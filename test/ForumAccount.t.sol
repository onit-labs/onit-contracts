// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// Forum 4337 contracts
import {ForumAccount} from "../src/erc4337-account/ForumAccount.sol";
import {ForumAccountFactory} from "../src/erc4337-account/ForumAccountFactory.sol";

// Infinitism 4337 contracts
import {EntryPoint} from "@erc4337/core/EntryPoint.sol";

import "./config/ERC4337TestConfig.t.sol";

contract ForumAccountTest is ERC4337TestConfig {
    // Variable used for test erc4337 account
    ForumAccount private deployed4337Account;
    address payable private deployed4337AccountAddress;

    bytes internal basicTransferCalldata;

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public {
        publicKey = createPublicKey(SIGNER_1);
        publicKey2 = createPublicKey(SIGNER_2);

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
        forumAccountSingleton.initialize(entryPointAddress, publicKey, address(1));

        // Deploy an account to be used in tests later
        deployed4337AccountAddress = forumAccountFactory.createForumAccount(publicKey);
        deployed4337Account = ForumAccount(deployed4337AccountAddress);

        // Deal funds to account
        deal(deployed4337AccountAddress, 1 ether);

        // Build a basic transaction to execute in some tests
        basicTransferCalldata = buildExecutionPayload(alice, uint256(0.5 ether), new bytes(0), Enum.Operation.Call);
    }

    /// -----------------------------------------------------------------------
    /// Deployment tests
    /// -----------------------------------------------------------------------

    function testFactoryCreateAccount() public {
        // Check that the account from setup is deployed and data is set on account, and safe
        assertEq(deployed4337Account.owner()[0], publicKey[0], "owner not set");
        assertEq(deployed4337Account.owner()[1], publicKey[1], "owner not set");
        assertEq(deployed4337Account.getThreshold(), 1, "threshold not set");
        assertEq(deployed4337Account.getOwners()[0], address(0xdead), "owner not set on safe");
        assertEq(address(deployed4337Account.entryPoint()), address(entryPoint), "entry point not set");

        // Can not initialize the same account twice
        vm.expectRevert("GS200");
        deployed4337Account.initialize(entryPointAddress, publicKey, address(1));
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
    address(handler)
    );

        // Deploy an account to be used in tests
        tmpMumbai = forumAccountFactory.createForumAccount(publicKey);

        // Fork Fuji and create an account from a fcatory
        vm.createSelectFork(vm.envString("FUJI_RPC_URL"));

        forumAccountFactory = new ForumAccountFactory(
    forumAccountSingleton,
    entryPointAddress,
    address(handler)
    );

        // Deploy an account to be used in tests
        tmpFuji = forumAccountFactory.createForumAccount(publicKey);

        assertEq(tmpMumbai, tmpFuji, "address not the same");
    }

    /// -----------------------------------------------------------------------
    /// Execution tests
    /// -----------------------------------------------------------------------

    // ! consider a limit to prevent changing entrypoint to a contract that is not compatible with 4337
    function testUpdateEntryPoint() public {
        // Check old entry point is set
        assertEq(address(deployed4337Account.entryPoint()), entryPointAddress, "entry point not set");

        // Build userop to set entrypoint to this contract as a test
        UserOperation memory userOp = buildUserOp(
            deployed4337AccountAddress,
            entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY),
            new bytes(0),
            abi.encodeWithSignature("setEntryPoint(address)", address(this))
        );

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Handle userOp
        entryPoint.handleOps(userOps, payable(this));

        // Check that the entry point has been updated
        assertEq(address(deployed4337Account.entryPoint()), address(this), "entry point not updated");
    }

    function testAccountTransfer() public {
        // Build user operation
        UserOperation memory userOp = buildUserOp(deployed4337AccountAddress, 0, new bytes(0), basicTransferCalldata);

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Check nonce before tx
        assertEq(entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY), 0, "nonce not correct");

        // Handle userOp
        entryPoint.handleOps(userOps, payable(address(this)));

        uint256 gas = calculateGas(userOp);

        // Check updated balances
        assertEq(deployed4337AccountAddress.balance, 0.5 ether - gas, "balance not updated");
        assertEq(alice.balance, 1.5 ether, "balance not updated");

        // Check account nonce
        assertEq(entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY), 1, "nonce not updated");
    }

    // Simulates adding an EOA owner to the safe (can act as a guardian in case of loss)
    function testAccountAddOwner() public {
        // Build payload to enable a module
        bytes memory addOwnerPayload =
            abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", address(this), 1);

        bytes memory payload =
            buildExecutionPayload(deployed4337AccountAddress, 0, addOwnerPayload, Enum.Operation.Call);

        // Build user operation
        UserOperation memory userOp = buildUserOp(
            deployed4337AccountAddress,
            entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY),
            new bytes(0),
            payload
        );

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Check nonce before tx
        assertEq(entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY), 0, "nonce not correct");

        // Handle userOp
        entryPoint.handleOps(userOps, payable(address(this)));

        uint256 gas = calculateGas(userOp);

        // Check updated balances
        assertEq(deployed4337AccountAddress.balance, 1 ether - gas, "balance not updated");
        // Check account nonce
        assertEq(entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY), 1, "nonce not updated");
        // Check module is enabled
        assertTrue(deployed4337Account.isOwner(address(this)), "owner not added");
    }

    // ! Double check with new validation including the domain seperator
    function testCannotReplaySig() public {
        // Build user operation
        UserOperation memory userOp = buildUserOp(deployed4337AccountAddress, 0, new bytes(0), basicTransferCalldata);

        UserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        // Check nonce before tx
        assertEq(entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY), 0, "nonce not correct");

        // Handle first userOp
        entryPoint.handleOps(userOps, payable(address(this)));

        assertEq(entryPoint.getNonce(deployed4337AccountAddress, BASE_NONCE_KEY), 1, "nonce not correct");

        vm.expectRevert();
        entryPoint.handleOps(userOps, payable(address(this)));
    }

    function testAddAndRemoveGuardian() public {
        UserOperation memory uop = UserOperation({
            sender: 0xeBd5d5f112DecCbEa152492470536F43Bd464cd2,
            nonce: 0,
            initCode: "0xcbaf5c43571d368117b7550b2f58c4864f3ccb2d5ea8282cd964ab6a5bfde42c652f28c4976b7662d0cc7bf2a65a3315a3c9d79b47d609215322400749db51cdb8655e162a123ee5117ea629611688437fdbacb348b02965",
            callData: "0x940d3c600000000000000000000000009c3c9283d3e44854697cd22d3faa240cfb03288900000000000000000000000000000000000000000000000000b1a2bc2ec50000000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004d0e30db000000000000000000000000000000000000000000000000000000000",
            callGasLimit: 215000,
            verificationGasLimit: 800000,
            preVerificationGas: 215000,
            maxFeePerGas: 883577090154,
            maxPriorityFeePerGas: 1500000000,
            paymasterAndData: "0x3b912be0270b59143985cc5c6aab452d99e2b4bb000000000000000000000000000000000000000000000000000000006447bbe50000000000000000000000000000000000000000000000000000000000000000c1ee375fedffaf81ba7d3512ef827e1e53c5a23ee88dfcc758032dd0f79152dd2e1deab2db84986e55c1790b0a37275f0ba86d2a41b7222e8fed41e1789a11601c",
            signature: "0x9b9c18ab82e7104cc0ce17dff8cc18fb1aa38e8de69c1c2eaecb73e9b461318c0b263b9e288ca2285fb9b7eeb424997de097cd79ecba6d41d1358ae2a938257700000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000247b2274797065223a22776562617574686e2e676574222c226368616c6c656e6765223a2200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002f222c226f726967696e223a2268747470733a2f2f646576656c6f706d656e742e666f72756d64616f732e636f6d227d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004a313538343438326664663761346430623765623964343563663833353238386362353965353562383234396666663335366533336265383865636335343664313164303030303030303000000000000000000000000000000000000000000000"
        });
        address[] memory owners = deployed4337Account.getOwners();
        assertEq(owners.length, 1, "should start with 1 owner");

        vm.startPrank(deployed4337AccountAddress);

        // Simulate adding an owner
        deployed4337Account.addOwnerWithThreshold(address(this), 1);

        owners = deployed4337Account.getOwners();
        assertEq(owners.length, 2, "owner not added");
        assertEq(owners[0], address(this), "incorrect owner");

        // Simulate swapping an owner (address(1) indicates sentinel owner, which is 'prev' in linked list)
        deployed4337Account.swapOwner(address(1), address(this), alice);

        owners = deployed4337Account.getOwners();
        assertEq(owners.length, 2, "incorrect number of owners");
        assertEq(owners[0], alice, "incorrect owner");

        // Simulate removing an owner
        deployed4337Account.removeOwner(address(1), alice, 1);

        owners = deployed4337Account.getOwners();
        assertEq(owners.length, 1, "owner not removed");
        assertEq(owners[0], address(0xdead), "incorrect owner");
    }

    /// -----------------------------------------------------------------------
    /// Helper functions
    /// -----------------------------------------------------------------------

    function accountSalt(uint256[2] memory owner) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner));
    }

    receive() external payable { // Allows this contract to receive ether
    }
}
