// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {
    CompatibilityFallbackHandler,
    Enum,
    Safe,
    Safe,
    SafeInstance,
    SafeProxyFactory,
    SafeTestConfig,
    SafeTestTools,
    SignMessageLib
} from "../config/SafeTestConfig.t.sol";
import {OnitAccountTestBase, OnitSmartWallet, OnitSmartWalletFactory} from "./OnitAccount.base.t.sol";
import {UserOperation} from "account-abstraction/interfaces/IAccount.sol";

contract OnitAccountAsSafeSignerTest is OnitAccountTestBase, SafeTestConfig {
    /// -----------------------------------------------------------------------
    /// Signature tests
    /// -----------------------------------------------------------------------

    function testSignAsAnOnitAccountOnSafe() public {
        bytes[] memory accountOwners = new bytes[](1);
        accountOwners[0] = abi.encodePacked(publicKeyBase[0], publicKeyBase[1]);

        OnitSmartWallet testAccount = OnitSmartWallet(onitAccountFactory.createAccount(accountOwners, 1));
        address testAccountAddress = address(testAccount);

        // Setup a test safe where the onit account is an owner
        address[] memory owners = new address[](2);
        owners[0] = alice;
        owners[1] = testAccountAddress;

        Safe testSafe = Safe(
            payable(
                proxyFactory.createProxyWithNonce(
                    address(singleton),
                    abi.encodeWithSignature(
                        "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                        owners,
                        1,
                        address(0),
                        new bytes(0),
                        address(0),
                        address(0),
                        0,
                        payable(0)
                    ),
                    0
                )
            )
        );
        vm.deal(address(testSafe), 1 ether);

        assertEq(address(testSafe).balance, 1 ether);
        assertEq(bob.balance, 100 ether);

        // Sign the safe tx with the passkey onit safe & format signature into webauthn format
        bytes memory sig = webauthnSignHash(
            testAccount.replaySafeHash(
                testSafe.getTransactionHash(
                    address(bob), 0.1 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), payable(0), 0
                )
            ),
            passkeyPrivateKey
        );

        bytes memory wrappedSig = abi.encode(0, sig);

        // format the sig into [r, s, v, signature] format (used for contract sigs on safe)
        bytes memory formattedSafeSig = abi.encode(address(uint160(owners[1])), uint256(128), uint8(0), wrappedSig);

        testSafe.execTransaction(
            address(bob), 0.1 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), payable(0), formattedSafeSig
        );

        assertEq(address(testSafe).balance, 0.9 ether);
        assertEq(bob.balance, 100.1 ether);
    }

    function testSignAsOwnerOnASafeViaEntrypoint() public {
        // Create a test onit account to sign the safe tx
        bytes[] memory accountOwners = new bytes[](1);
        accountOwners[0] = abi.encodePacked(publicKeyBase[0], publicKeyBase[1]);
        OnitSmartWallet testAccount = OnitSmartWallet(onitAccountFactory.createAccount(accountOwners, 1));
        address testAccountAddress = address(testAccount);

        // Give test account some funds and set deposit on entrypoint for later call
        vm.deal(testAccountAddress, 1 ether);
        entryPointV6.depositTo{value: 0.1 ether}(testAccountAddress);

        // Setup a test safe where the onit account is an owner
        address[] memory owners = new address[](2);
        owners[0] = alice;
        owners[1] = testAccountAddress;

        Safe testSafe = Safe(
            payable(
                proxyFactory.createProxyWithNonce(
                    address(singleton),
                    abi.encodeWithSignature(
                        "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                        owners,
                        1,
                        address(0),
                        new bytes(0),
                        address(0),
                        address(0),
                        0,
                        payable(0)
                    ),
                    0
                )
            )
        );
        vm.deal(address(testSafe), 1 ether);

        assertEq(address(testSafe).balance, 1 ether);
        assertEq(bob.balance, 100 ether);

        // Sign the safe tx with the passkey onit safe & format signature into webauthn format
        bytes memory sig = webauthnSignHash(
            testAccount.replaySafeHash(
                testSafe.getTransactionHash(bob, 0.1 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), payable(0), 0)
            ),
            passkeyPrivateKey
        );

        bytes memory wrappedSig = abi.encode(0, sig);

        // Format the sig into [r, s, v, signature] format (used for contract sigs on safe)
        bytes memory formattedSafeSig = abi.encode(address(uint160(owners[1])), uint256(128), uint8(0), wrappedSig);

        // Create the calldata the entrypoint will execute for the passkey account
        bytes memory executeTxCalldata = abi.encodeWithSelector(
            OnitSmartWallet.execute.selector,
            address(testSafe),
            0,
            abi.encodeWithSelector(
                testSafe.execTransaction.selector,
                bob,
                0.1 ether,
                "",
                Enum.Operation.Call,
                0,
                0,
                0,
                address(0),
                payable(0),
                formattedSafeSig
            )
        );

        // Create the user operation for the passkey account
        UserOperation memory userOp = buildUserOp(testAccountAddress, 0, new bytes(0), executeTxCalldata);

        // Sign the user operation and format signature into webauthn format to verify
        userOp = webauthnSignUserOperation(userOp, passkeyPrivateKey);

        // Wrap the userop sig for the onit wallet to execute the userop
        userOp.signature = abi.encode(0, userOp.signature);

        // Execute the call from the Onit account via the entrypoint
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;
        entryPointV6.handleOps(userOps, payable(alice));

        assertEq(address(testSafe).balance, 0.9 ether);
        assertEq(bob.balance, 100.1 ether);
    }

    // TODO create a SigMessageLib contract for our replaySafeHashes on the Onit account
    // function testSignMessage() public returns (Safe testSafe, bytes32 messageHash) {
    //     // Setup a test safe where the onit account is an owner
    //     address[] memory owners = new address[](2);
    //     owners[0] = alice;
    //     owners[1] = onitAccountAddress;

    //     testSafe = Safe(
    //         payable(
    //             proxyFactory.createProxyWithNonce(
    //                 address(singleton),
    //                 abi.encodeWithSignature(
    //                     "setup(address[],uint256,address,bytes,address,address,uint256,address)",
    //                     owners,
    //                     1,
    //                     address(0),
    //                     new bytes(0),
    //                     address(0),
    //                     address(0),
    //                     0,
    //                     payable(0)
    //                 ),
    //                 0
    //             )
    //         )
    //     );

    //     // Get the message hash required to authorize some transaction
    //     bytes memory transferCalldata = testSafe.encodeTransactionData(
    //         address(onitAccountAddress), 0.1 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), payable(0), 0
    //     );
    //     messageHash = onitAccount.getMessageHash(transferCalldata);
    //     assertEq(onitAccount.signedMessages(messageHash), 0);

    //     // Create a userop to set the signed message on the onit safe
    //     bytes memory signMessageCalldata = abi.encodeWithSelector(signMessageLib.signMessage.selector,
    // transferCalldata);
    //     bytes memory executeSignMessageCalldata = abi.encodeWithSelector(
    //         Onit4337Wrapper.delegateExecute.selector, address(signMessageLib), signMessageCalldata
    //     );
    //     PackedUserOperation memory userOp = buildUserOp(onitAccountAddress, 0, new bytes(0),
    // executeSignMessageCalldata);

    //     // Sign the userop with the passkey onit safe & format signature into webauthn format
    //     userOp = webauthnSignUserOperation(userOp, passkeyPrivateKey);

    //     // Execute the call from the Onit account via the entrypoint
    //     PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
    //     userOps[0] = userOp;
    //     entryPoint.handleOps(userOps, payable(alice));

    //     assertEq(onitAccount.signedMessages(messageHash), 1);
    // }

    // function testSignWithSignedMessageAsOwnerOnSafe() public {
    //     (Safe testSafe, bytes32 messageHash) = testSignMessage();
    //     vm.deal(address(testSafe), 1 ether);

    //     assertEq(onitAccount.signedMessages(messageHash), 1);
    //     assertEq(address(testSafe).balance, 1 ether);

    //     // Form the messageHash signature for the Safe - bytes(0) for sig since we'll use the signed message
    //     bytes memory safeSig = abi.encode(onitAccountAddress, uint256(128), uint8(0), new bytes(0));

    //     // Execute the transaction on the Safe
    //     testSafe.execTransaction(
    //         address(onitAccountAddress), 0.1 ether, "", Enum.Operation.Call, 0, 0, 0, address(0), payable(0), safeSig
    //     );

    //     assertEq(address(testSafe).balance, 0.9 ether);
    // }
}
