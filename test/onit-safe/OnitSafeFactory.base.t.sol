// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../config/ERC4337TestConfig.t.sol";
import "../config/SafeTestConfig.t.sol";
import "../config/AddressTestConfig.t.sol";

import {WebAuthnUtils, WebAuthnInfo} from "../../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Base64} from "../../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Base64.sol";

import {OnitSafe} from "../../src/onit-safe/OnitSafe.sol";
import {OnitSafeFactory} from "../../src/onit-safe/OnitSafeFactory.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe
 */
contract OnitSafeFactoryTestBase is AddressTestConfig, ERC4337TestConfig, SafeTestConfig {
    // The Onit account is a Safe controlled by an ERC4337 module with passkey signer
    OnitSafe internal onitAccount;
    address payable internal onitAccountAddress;

    // The Onit Safe singleton is where the passkey is verified
    OnitSafe internal onitSafe;

    OnitSafeFactory internal onitSafeFactory;
    address internal onitSafeFactoryAddress;

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
        onitSafeFactory =
            new OnitSafeFactory(address(proxyFactory), address(addModulesLib), address(singleton), entryPointAddress);
        onitSafeFactoryAddress = address(onitSafeFactory);
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testFactorySetupCorrectly() public {
        assertEq(address(onitSafeFactory.proxyFactory()), address(proxyFactory));
        assertEq(onitSafeFactory.addModulesLibAddress(), address(addModulesLib));
        assertEq(onitSafeFactory.safeSingletonAddress(), address(singleton));
        assertEq(onitSafeFactory.entryPointAddress(), entryPointAddress);
    }

    // test that entrypoint and other values are set correctly

    /// -----------------------------------------------------------------------
    /// Create account tests
    /// -----------------------------------------------------------------------

    function testCreateOnitSafe() public {
        onitAccountAddress = onitSafeFactory.createOnitSafe(publicKeyBase, 0);
        onitAccount = OnitSafe(onitAccountAddress);

        assertEq(onitAccount.getOwners()[0], address(0xdead));
        assertEq(onitAccount.getThreshold(), 1);
        // assertTrue(onitAccount.isModuleEnabled(address(onitSafeModule)));

        assertEq(address(onitAccount.entryPoint()), entryPointAddress);
        assertEq(onitAccount.owner()[0], publicKeyBase[0]);
        assertEq(onitAccount.owner()[1], publicKeyBase[1]);
    }
    /// -----------------------------------------------------------------------
    /// Execution tests
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Utils
    /// -----------------------------------------------------------------------

    receive() external payable { // Allows this contract to receive ether
    }
}
