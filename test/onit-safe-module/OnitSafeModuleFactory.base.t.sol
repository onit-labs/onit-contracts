// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OnitSafeTestCommon, Enum, PackedUserOperation, OnitSafe} from "../OnitSafe.common.t.sol";

import {WebAuthnUtils, WebAuthnInfo} from "../../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Base64} from "../../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Base64.sol";

import {OnitSafeModule} from "../../src/onit-safe-module/OnitSafeModule.sol";
import {OnitSafeModuleFactory} from "../../src/onit-safe-module/OnitSafeModuleFactory.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe Module
 */
contract OnitSafeModuleFactoryTestBase is OnitSafeTestCommon {
    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public virtual {
        onitSafeModuleFactory = new OnitSafeModuleFactory(
            address(proxyFactory), address(addModulesLib), address(singleton), entryPointAddress
        );
        onitSafeModuleFactoryAddress = address(onitSafeModuleFactory);
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testFactorySetupCorrectly() public {
        assertEq(address(onitSafeModuleFactory.proxyFactory()), address(proxyFactory));
        assertEq(onitSafeModuleFactory.addModulesLibAddress(), address(addModulesLib));
        assertEq(onitSafeModuleFactory.safeSingletonAddress(), address(singleton));
        assertEq(onitSafeModuleFactory.entryPointAddress(), entryPointAddress);
    }

    // test that entrypoint and other values are set correctly

    /// -----------------------------------------------------------------------
    /// Validation tests
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Execution tests
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Utils
    /// -----------------------------------------------------------------------
}
