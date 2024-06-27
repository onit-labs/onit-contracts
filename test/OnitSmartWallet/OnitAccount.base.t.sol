// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OnitSmartWallet, OnitSmartWalletFactory, OnitSmartWalletTestCommon} from "../OnitSmartWallet.common.t.sol";

/**
 * @notice Some variables and functions used to test the Onit Account
 * @dev More in depth tests of the Onit Smart Wallet can be found in the Onit Smart Wallet repo
 *      https://github.com/onit-labs/smart-wallet
 */
contract OnitAccountTestBase is OnitSmartWalletTestCommon {
    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------
    function setUp() public virtual {
        // Deploy contracts
        onitSingleton = new OnitSmartWallet();
        onitAccountFactory = new OnitSmartWalletFactory(address(onitSingleton));
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testOnitSingletonDeployedCorrectly() public {
        assertEq(address(onitSingleton.entryPoint()), ENTRY_POINT_V6);
        assertEq(entryPointV7.getNonce(address(onitSingleton), 0), 0);
        assertEq(onitSingleton.isOwnerAddress(address(0)), true);
        assertEq(onitSingleton.nextOwnerIndex(), 1);
    }

    // /// -----------------------------------------------------------------------
    // /// Utils
    // /// -----------------------------------------------------------------------

    // Build payload which the entryPoint will call on the sender Onit 4337 account
    function buildExecutionPayload(address to, uint256 value, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("execute(address,uint256,bytes)", to, value, data);
    }

    // Build delegateExecution payload
    function buildDelegateExecutionPayload(address delegate, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("delegateExecute(address,bytes)", delegate, data);
    }
}
