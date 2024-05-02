// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OnitAccountTestCommon, OnitAccount, OnitAccountProxyFactory} from "../OnitAccount.common.t.sol";

import {WebAuthnUtils, WebAuthnInfo} from "../../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Base64} from "../../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Base64.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe
 */
contract OnitAccountFactoryTestBase is OnitAccountTestCommon {
    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public virtual {
        // Deploy contracts
        onitSingleton = new OnitAccount();
        onitAccountFactory = new OnitAccountProxyFactory(address(handler), address(onitSingleton));
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testFactorySetupCorrectly() public {
        assertEq(address(onitAccountFactory.compatibilityFallbackHandler()), address(handler));
        assertEq(onitAccountFactory.safeSingletonAddress(), address(onitSingleton));
    }

    /// -----------------------------------------------------------------------
    /// Create account tests
    /// -----------------------------------------------------------------------

    function testCreateOnitAccount() public {
        onitAccountAddress = payable(onitAccountFactory.createAccount(publicKeyBase[0], publicKeyBase[1], 0));
        onitAccount = OnitAccount(onitAccountAddress);

        // Check Safe values
        assertEq(onitAccount.getOwners()[0], address(0xdead));
        assertEq(onitAccount.getThreshold(), 1);
        // Check Onit values
        assertEq(address(onitAccount.entryPoint()), entryPointAddress);
        assertEq(onitAccount.owner()[0], publicKeyBase[0]);
        assertEq(onitAccount.owner()[1], publicKeyBase[1]);
        _checkImplementationSlot(address(onitAccount), address(onitSingleton));
    }

    function testGetAddressMatchesDeployedAddress() public {
        bytes32 salt = keccak256(abi.encodePacked(publicKeyBase[0], publicKeyBase[1], uint256(0)));
        address predictedAddress = onitAccountFactory.getAddress(salt);

        onitAccountAddress = payable(onitAccountFactory.createAccount(publicKeyBase[0], publicKeyBase[1], 0));
        assertEq(predictedAddress, onitAccountAddress);
    }

    /// -----------------------------------------------------------------------
    /// Utils
    /// -----------------------------------------------------------------------

    function _checkImplementationSlot(address proxy, address implementation_) internal {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        assertEq(vm.load(proxy, slot), bytes32(uint256(uint160(implementation_))));
    }
}
