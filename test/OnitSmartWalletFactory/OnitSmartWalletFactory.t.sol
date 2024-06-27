// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OnitSmartWallet, OnitSmartWalletFactory, OnitSmartWalletTestCommon} from "../OnitSmartWallet.common.t.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe
 * @dev More in depth tests of the Onit Smart Wallet can be found in the Onit Smart Wallet repo
 *      https://github.com/onit-labs/smart-wallet
 */
contract OnitAccountFactoryTestBase is OnitSmartWalletTestCommon {
    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public virtual {
        onitSingleton = new OnitSmartWallet();
        onitAccountFactory = new OnitSmartWalletFactory(address(onitSingleton));
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testFactorySetupCorrectly() public {
        assertEq(onitAccountFactory.implementation(), address(onitSingleton));
    }
}
