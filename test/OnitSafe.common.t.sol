// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "./config/AddressTestConfig.t.sol";
import "./config/ERC4337TestConfig.t.sol";
import "./config/SafeTestConfig.t.sol";
import "forge-std/console.sol";

import {OnitSafe} from "../../src/onit-safe/OnitSafe.sol";
import {OnitSafeFactory} from "../../src/onit-safe/OnitSafeFactory.sol";

import {OnitSafeModule} from "../../src/onit-safe-module/OnitSafeModule.sol";
import {OnitSafeModuleFactory} from "../../src/onit-safe-module/OnitSafeModuleFactory.sol";

/**
 * @notice Some variables and functions used in most tests of the Onit Safe
 */
contract OnitSafeTestCommon is AddressTestConfig, ERC4337TestConfig, SafeTestConfig {
    OnitSafe internal onitSingleton;

    // The Onit account is a Safe controlled by an ERC4337 module with passkey signer
    OnitSafe internal onitAccount;
    address payable internal onitAccountAddress;

    // The Onit account factory
    OnitSafeFactory internal onitSafeFactory;
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

    receive() external payable { // Allows this contract to receive ether
    }
}
