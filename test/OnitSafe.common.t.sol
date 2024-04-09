// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// Test config imports
import "./config/AddressTestConfig.t.sol";
import "./config/ERC4337TestConfig.t.sol";
import "./config/SafeTestConfig.t.sol";
import "forge-std/console.sol";

// Webauthn imports for handling passkey signatures
import {WebAuthnUtils, WebAuthnInfo} from "../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../lib/webauthn-sol/src/WebAuthn.sol";
import {Base64} from "../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Base64.sol";

import {Onit4337Wrapper} from "../src/Onit4337Wrapper.sol";

// Onit Safe imports
import {OnitSafe} from "../src/onit-safe/OnitSafe.sol";
import {OnitSafeProxyFactory} from "../src/onit-safe/OnitSafeFactory.sol";

// Onit Safe Module imports
import {OnitSafeModule} from "../src/onit-safe-module/OnitSafeModule.sol";
import {OnitSafeModuleFactory} from "../src/onit-safe-module/OnitSafeModuleFactory.sol";

/**
 * @notice Some variables and functions used in most tests of the Onit Safe
 */
contract OnitSafeTestCommon is AddressTestConfig, ERC4337TestConfig, SafeTestConfig {
    OnitSafe internal onitSingleton;

    // The Onit account is a Safe controlled by an ERC4337 module with passkey signer
    OnitSafe internal onitAccount;
    address payable internal onitAccountAddress;

    // The Onit account factory
    OnitSafeProxyFactory internal onitSafeFactory;
    address internal onitSafeFactoryAddress;

    // The Onit account module - WIP!
    OnitSafeModule internal onitSafeModule;
    address internal onitSafeModuleAddress;

    // The Onit account module factory - WIP!
    OnitSafeModuleFactory internal onitSafeModuleFactory;
    address internal onitSafeModuleFactoryAddress;

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

    // /// -----------------------------------------------------------------------
    // /// Utils
    // /// -----------------------------------------------------------------------

    function webauthnSignUserOperation(
        PackedUserOperation memory userOp,
        uint256 privateKey
    ) internal returns (PackedUserOperation memory) {
        // Get the webauthn struct which will be verified by the module
        bytes32 challenge = entryPoint.getUserOpHash(userOp);

        // Sign the challenge with the private key
        bytes memory pksig = webauthnSignHash(challenge, privateKey);
        userOp.signature = pksig;

        return userOp;
    }

    function webauthnSignHash(bytes32 hash, uint256 privateKey) internal view returns (bytes memory) {
        // Get the webauthn struct which will be verified by the module
        WebAuthnInfo memory webAuthn = WebAuthnUtils.getWebAuthnStruct(hash, authenticatorData, origin);

        (bytes32 r, bytes32 s) = vm.signP256(privateKey, webAuthn.messageHash);

        // Format the signature data
        bytes memory pksig = abi.encode(
            WebAuthn.WebAuthnAuth({
                authenticatorData: webAuthn.authenticatorData,
                clientDataJSON: webAuthn.clientDataJSON,
                typeIndex: 1,
                challengeIndex: 23,
                r: uint256(r),
                s: sMalleabilityCheck(uint256(s))
            })
        );

        return pksig;
    }

    function sMalleabilityCheck(uint256 s) internal pure returns (uint256 checkedS) {
        checkedS = s;

        // Values from the P256 curve
        uint256 P256_N = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;
        uint256 P256_N_DIV_2 =
            57_896_044_605_178_124_381_348_723_474_703_786_764_998_477_612_067_880_171_211_129_530_534_256_022_184;

        if (uint256(s) > P256_N_DIV_2) {
            // Use complement to get the correct s value
            // https://github.com/indutny/elliptic/blob/75700785ff41bb5d029d19186beff26d4883caa5/lib/elliptic/ec/index.js#L147
            checkedS = (P256_N - uint256(s)) % P256_N;
        }
    }

    receive() external payable { // Allows this contract to receive ether
    }
}
