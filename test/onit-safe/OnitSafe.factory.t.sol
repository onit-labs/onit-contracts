// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OnitSafeTestCommon, OnitSafe, OnitSafeProxyFactory} from "../OnitSafe.common.t.sol";

import {WebAuthnUtils, WebAuthnInfo} from "../../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Base64} from "../../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Base64.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe
 */
contract OnitSafeFactoryTestBase is OnitSafeTestCommon {
    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public virtual {
        //onitSafeFactory =
        //new OnitSafeFactory(address(proxyFactory), address(addModulesLib), address(singleton), entryPointAddress);
        onitSafeFactoryAddress = address(onitSafeFactory);
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    // function testFactorySetupCorrectly() public {
    //     assertEq(address(onitSafeFactory.proxyFactory()), address(proxyFactory));
    //     assertEq(onitSafeFactory.addModulesLibAddress(), address(addModulesLib));
    //     assertEq(onitSafeFactory.safeSingletonAddress(), address(singleton));
    //     assertEq(onitSafeFactory.entryPointAddress(), entryPointAddress);
    // }

    // test that entrypoint and other values are set correctly

    /// -----------------------------------------------------------------------
    /// Create account tests
    /// -----------------------------------------------------------------------

    // function testCreateOnitSafe() public {
    //     onitAccountAddress = onitSafeFactory.createOnitSafe(publicKeyBase, 0);
    //     onitAccount = OnitSafe(onitAccountAddress);

    //     assertEq(onitAccount.getOwners()[0], address(0xdead));
    //     assertEq(onitAccount.getThreshold(), 1);
    //     // assertTrue(onitAccount.isModuleEnabled(address(onitSafeModule)));

    //     assertEq(address(onitAccount.entryPoint()), entryPointAddress);
    //     assertEq(onitAccount.owner()[0], publicKeyBase[0]);
    //     assertEq(onitAccount.owner()[1], publicKeyBase[1]);
    // }
    /// -----------------------------------------------------------------------
    /// Execution tests
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Utils
    /// -----------------------------------------------------------------------
}
