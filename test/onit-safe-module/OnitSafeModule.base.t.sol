// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../config/ERC4337TestConfig.t.sol";
import "../config/SafeTestConfig.t.sol";

import {BasicTestConfig} from "../../lib/fast-foundry-template/test/config/BasicTestConfig.t.sol";

import {OnitSafeModule} from "../../src/onit-safe-module/OnitSafeModule.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe Module
 */
contract OnitSafeModuleTestBase is BasicTestConfig, ERC4337TestConfig, SafeTestConfig {
    // The Onit account is a Safe controlled by an ERC4337 module with passkey signer
    Safe internal onitAccount;
    address payable internal onitAccountAddress;

    // The Onit Safe Module is where the passkey is verified
    OnitSafeModule internal onitSafeModule;

    // Some calldata for transactions
    bytes internal basicTransferCalldata;

    // Some public keys used as signers in tests
    uint256[2] internal publicKey;
    uint256[2] internal publicKey2;
    uint256[2][] internal inputMembers;

    string internal constant SIGNER_1 = "1";
    string internal constant SIGNER_2 = "2";

    string internal authentacatorData = "1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000";

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public virtual {
        publicKey = createPublicKey(SIGNER_1);
        publicKey2 = createPublicKey(SIGNER_2);

        // deploy module with pk and ep
        deployOnitAccount();

        // Deal funds to account
        deal(onitAccountAddress, 1 ether);

        // Build a basic transaction to execute in some tests
        //basicTransferCalldata = buildExecutionPayload(alice, uint256(0.5 ether), "", Enum.Operation.Call);
    }

    // See https://github.com/safe-global/safe-modules/modules/4337/README.md
    function deployOnitAccount() internal {
        // Deploy module with passkey
        onitSafeModule = new OnitSafeModule(entryPointAddress, publicKey);

        address[] memory modules = new address[](1);
        modules[0] = address(onitSafeModule);

        // Placeholder owners
        address[] memory owners = new address[](1);
        owners[0] = address(0xdead);

        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners,
            1,
            address(addModulesLib),
            abi.encodeWithSignature("enableModules(address[])", modules),
            address(onitSafeModule),
            address(0),
            0,
            address(0)
        );

        // bytes memory initCallData =
        //     abi.encodeWithSignature("createProxyWithNonce(address,bytes,uint256)", address(singleton), initializer, 99);

        // bytes memory initCode = abi.encodePacked(address(proxyFactory), initCallData);

        onitAccountAddress = payable(proxyFactory.createProxyWithNonce(address(singleton), initializer, 99));
        onitAccount = Safe(onitAccountAddress);
    }

    /// -----------------------------------------------------------------------
    /// Setup tests
    /// -----------------------------------------------------------------------

    function testOnitAccountDeployedCorrectly() public {
        assertEq(onitAccount.getOwners()[0], address(0xdead));
        assertEq(onitAccount.getThreshold(), 1);
        assertTrue(onitAccount.isModuleEnabled(address(onitSafeModule)));

        assertEq(address(onitSafeModule.entryPoint()), entryPointAddress);
        assertEq(onitSafeModule.owner()[0], publicKey[0]);
        assertEq(onitSafeModule.owner()[1], publicKey[1]);
    }

    // test that entrypoint and other values are set correctly

    /// -----------------------------------------------------------------------
    /// Validation tests
    /// -----------------------------------------------------------------------

    function testFailsIfNotFromEntryPoint() public {
        onitSafeModule.validateUserOp(userOpBase, entryPoint.getUserOpHash(userOpBase), 0);
    }

    function testValidateUserOp() public {
        bytes memory transferCalldata = abi.encodeWithSignature("transfer(address,uint256)", alice, 1 ether);

        PackedUserOperation memory userOp = buildUserOp(onitAccountAddress, 0, new bytes(0), transferCalldata);

        PackedUserOperation[] memory userOps = signAndFormatUserOpIndividual(userOp, SIGNER_1);

        entryPoint.handleOps(userOps, payable(alice));
    }

    /// -----------------------------------------------------------------------
    /// HELPERS
    /// -----------------------------------------------------------------------

    function accountSalt(uint256[2] memory owner) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner));
    }

    receive() external payable { // Allows this contract to receive ether
    }
}
