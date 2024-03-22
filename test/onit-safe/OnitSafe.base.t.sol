// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../config/ERC4337TestConfig.t.sol";
import "../config/SafeTestConfig.t.sol";
import "../config/AddressTestConfig.t.sol";
import "forge-std/console.sol";

import {WebAuthnUtils, WebAuthnInfo} from "../../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Base64} from "../../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Base64.sol";

import {OnitSafe} from "../../src/onit-safe/OnitSafe.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe Module
 */
contract OnitSafeTestBase is AddressTestConfig, ERC4337TestConfig, SafeTestConfig {
    OnitSafe internal onitSingleton;
    
    // The Onit account is a Safe controlled by an ERC4337 module with passkey signer
    OnitSafe internal onitAccount;
    address payable internal onitAccountAddress;

    // Some calldata for transactions
    bytes internal basicTransferCalldata;

    // Base values - see smart-wallet demo repo //
    bytes authenticatorData = hex"49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97630500000000";
    string origin = "https://sign.coinbase.com";
    // Public & private key for testing with base auth data
    uint256[2] internal publicKeyBase = [
        0x1c05286fe694493eae33312f2d2e0d0abeda8db76238b7a204be1fb87f54ce42,
        0x28fef61ef4ac300f631657635c28e59bfb2fe71bce1634c81c65642042f6dc4d
    ];
    uint256 passkeyPrivateKey = uint256(0x03d99692017473e2d631945a812607b23269d85721e0f370b8d3e7d29a874fd2);

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public virtual {
        // deploy module with pk and ep
        deployOnitAccount(publicKeyBase);

        // Deal funds to account
        deal(onitAccountAddress, 1 ether);

        // Build a basic transaction to execute in some tests
        //basicTransferCalldata = buildExecutionPayload(alice, uint256(0.5 ether), "", Enum.Operation.Call);
    }

    // See https://github.com/safe-global/safe-modules/modules/4337/README.md
    function deployOnitAccount(uint256[2] memory pk) internal {
        // Deploy module with passkey public key as owner
        onitSingleton = new OnitSafe();

        // address[] memory modules = new address[](1);
        // modules[0] = address(onitSafeModule);

        // Placeholder owners
        address[] memory owners = new address[](1);
        owners[0] = address(0xdead);

        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners,
            1,
            address(0),
            new bytes (0), // abi.encodeWithSignature("enableModules(address[])", modules),
            address(handler),
            address(0),
            0,
            address(0)
        );

        // bytes memory initCallData =
        //     abi.encodeWithSignature("createProxyWithNonce(address,bytes,uint256)", address(singleton), initializer, 99);

        // bytes memory initCode = abi.encodePacked(address(proxyFactory), initCallData);

        onitAccountAddress = payable(proxyFactory.createProxyWithNonce(address(onitSingleton), initializer, 99));
        onitAccount = OnitSafe(onitAccountAddress);

        deal(onitAccountAddress, 1 ether);
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testOnitAccountDeployedCorrectly() public {
        //assertEq(onitAccount.getOwners()[0], address(0xdead));
        assertEq(onitAccount.getThreshold(), 1);
       // assertTrue(onitAccount.isModuleEnabled(address(onitSafeModule)));

        assertEq(address(onitAccount.entryPoint()), entryPointAddress);
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

    receive() external payable { // Allows this contract to receive ether
    }
}
