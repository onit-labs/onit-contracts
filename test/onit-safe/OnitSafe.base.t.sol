// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OnitSafeTestCommon, Enum, PackedUserOperation, OnitSafe, OnitSafeProxyFactory} from "../OnitSafe.common.t.sol";

import {WebAuthnUtils, WebAuthnInfo} from "../../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Base64} from "../../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Base64.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe Module
 */
contract OnitSafeTestBase is OnitSafeTestCommon {
    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------
    function setUp() public virtual {
        // Deploy contracts
        onitSingleton = new OnitSafe();
        onitSafeFactory = new OnitSafeProxyFactory(address(handler), address(onitSingleton));

        onitAccount = OnitSafe(payable(onitSafeFactory.createAccount(publicKeyBase, keccak256("a"))));
        onitAccountAddress = payable(address(onitAccount));

        // Deal funds to account
        deal(onitAccountAddress, 1 ether);

        // Build a basic transaction to execute in some tests
        //basicTransferCalldata = buildExecutionPayload(alice, uint256(0.5 ether), "", Enum.Operation.Call);
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testCannotSetupSingleton() public {
        // Try to setup the Onit function on singleton
        vm.expectRevert(OnitSafe.AlreadyInitialized.selector);
        onitSingleton.setupOnitSafe(publicKeyBase);

        // Check that the owner is still the placeholder
        assertEq(onitSingleton.owner()[0], 1);
        assertEq(onitSingleton.owner()[1], 1);

        address[] memory owners = new address[](1);
        owners[0] = address(0xdead);

        // Try to setup the safe function on singleton
        vm.expectRevert("GS200");
        onitSingleton.setup(owners, 1, address(0), new bytes(0), address(0), address(0), 0, payable(0));
    }

    function testOnitAccountDeployedCorrectly() public {
        // Safe variables set
        assertEq(onitAccount.getOwners()[0], address(0xdead));
        assertEq(onitAccount.getThreshold(), 1);

        // 4337 variables set
        assertEq(address(onitAccount.entryPoint()), entryPointAddress);
        assertEq(onitAccount.getNonce(), 0);
        assertEq(onitAccount.owner()[0], publicKeyBase[0]);
        assertEq(onitAccount.owner()[1], publicKeyBase[1]);
    }

    // test that entrypoint and other values are set correctly

    /// -----------------------------------------------------------------------
    /// Validation tests
    /// -----------------------------------------------------------------------

    // function testFailsIfNotFromEntryPoint() public {
    //     onitSafeModule.validateUserOp(userOpBase, entryPoint.getUserOpHash(userOpBase), 0);
    // }

    // function testValidateUserOp() public {
    //     // Some basic user operation
    //     PackedUserOperation memory userOp = buildUserOp(onitAccountAddress, 0, new bytes(0), new bytes(0));

    //     // Get the webauthn struct which will be verified by the module
    //     bytes32 challenge = entryPoint.getUserOpHash(userOp);
    //     WebAuthnInfo memory webAuthn = WebAuthnUtils.getWebAuthnStruct(challenge, authenticatorData, origin);

    //     (bytes32 r, bytes32 s) = vm.signP256(passkeyPrivateKey, webAuthn.messageHash);

    //     // Format the signature data
    //     bytes memory pksig = abi.encode(
    //         WebAuthn.WebAuthnAuth({
    //             authenticatorData: webAuthn.authenticatorData,
    //             clientDataJSON: webAuthn.clientDataJSON,
    //             typeIndex: 1,
    //             challengeIndex: 23,
    //             r: uint256(r),
    //             s: uint256(s)
    //         })
    //     );
    //     userOp.signature = pksig;

    //     bytes memory validateUserOpCalldata =
    //         abi.encodeWithSelector(OnitSafeModule.validateUserOp.selector, userOp, challenge, 0);

    //     // We prank entrypoint and call like this so the safe handler context passes the _requireFromEntryPoint check
    //     vm.prank(entryPointAddress);
    //     (, bytes memory validationData) = onitAccountAddress.call(validateUserOpCalldata);

    //     assertEq(keccak256(validationData), keccak256(abi.encodePacked(uint256(0))));
    // }

    // /// -----------------------------------------------------------------------
    // /// Execution tests
    // /// -----------------------------------------------------------------------

    // // TODO fix general txdata signing
    // function testExecuteTx() public {
    //     // Init values for test
    //     uint256 aliceBalanceBefore = alice.balance;
    //     uint256 onitAccountBalanceBefore = onitAccountAddress.balance;
    //     uint256 transferAmount = 0.1 ether;

    //     // Some transfer user operation
    //     bytes memory transferExecutionCalldata = new bytes(0);
    //     //buildExecutionPayload(alice, transferAmount, new bytes(0), Enum.Operation.Call);

    //     //PackedUserOperation memory userOp = buildUserOp(onitAccountAddress, 0, new bytes(0), tmp1);
    //     PackedUserOperation memory userOp = buildUserOp(onitAccountAddress, 0, new bytes(0), transferExecutionCalldata);

    //     // Get the webauthn struct which will be verified by the module
    //     bytes32 challenge = entryPoint.getUserOpHash(userOp);
    //     WebAuthnInfo memory webAuthn = WebAuthnUtils.getWebAuthnStruct(challenge, authenticatorData, origin);

    //     (bytes32 r, bytes32 s) = vm.signP256(passkeyPrivateKey, webAuthn.messageHash);

    //     // Format the signature data
    //     bytes memory pksig = abi.encode(
    //         WebAuthn.WebAuthnAuth({
    //             authenticatorData: webAuthn.authenticatorData,
    //             clientDataJSON: webAuthn.clientDataJSON,
    //             typeIndex: 1,
    //             challengeIndex: 23,
    //             r: uint256(r),
    //             s: uint256(s)
    //         })
    //     );

    //     PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
    //     userOps[0] = userOp;
    //     userOp.signature = pksig;

    //     entryPoint.handleOps(userOps, payable(alice));
    // }

    // /// -----------------------------------------------------------------------
    // /// Utils
    // /// -----------------------------------------------------------------------

    // // Build payload which the entryPoint will call on the sender Onit 4337 account
    // function buildExecutionPayload(
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     Enum.Operation operation
    // ) internal pure returns (bytes memory) {
    //     return abi.encodeWithSignature("executeUserOp(address,uint256,bytes,uint8)", to, value, data, uint8(0));
    // }
}
