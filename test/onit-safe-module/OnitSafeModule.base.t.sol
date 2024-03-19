// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../config/ERC4337TestConfig.t.sol";
import "../config/SafeTestConfig.t.sol";
import "../config/AddressTestConfig.t.sol";

import {WebAuthnUtils, WebAuthnInfo} from "../../src/utils/WebAuthnUtils.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";

import {OnitSafeModule} from "../../src/onit-safe-module/OnitSafeModule.sol";

/**
 * @notice Some variables and functions used to test the Onit Safe Module
 */
contract OnitSafeModuleTestBase is AddressTestConfig, ERC4337TestConfig, SafeTestConfig {
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

    string internal authentacatorDataOnit = "1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000";

    // base values //
    bytes authenticatorData = hex"49960de5880e8c687434170f6476605b8fe4aeb9a28632c7995cf3ba831d97630500000000";
    string origin = "https://sign.coinbase.com";
    // Tmp public key for testing with base auth data
    uint256[2] internal pk = [
        0x1c05286fe694493eae33312f2d2e0d0abeda8db76238b7a204be1fb87f54ce42,
        0x28fef61ef4ac300f631657635c28e59bfb2fe71bce1634c81c65642042f6dc4d
    ];
    // Tmp private key for testing with base auth data
    uint256 passkeyPrivateKey = uint256(0x03d99692017473e2d631945a812607b23269d85721e0f370b8d3e7d29a874fd2);

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
        onitSafeModule = new OnitSafeModule(entryPointAddress, pk);

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
        assertEq(onitSafeModule.owner()[0], pk[0]);
        assertEq(onitSafeModule.owner()[1], pk[1]);
    }

    // test that entrypoint and other values are set correctly

    /// -----------------------------------------------------------------------
    /// Validation tests
    /// -----------------------------------------------------------------------

    function testFailsIfNotFromEntryPoint() public {
        onitSafeModule.validateUserOp(userOpBase, entryPoint.getUserOpHash(userOpBase), 0);
    }

    function testValidateUserOp() public {
        // Some basic user operation
        PackedUserOperation memory userOp = buildUserOp(onitAccountAddress, 0, new bytes(0), new bytes(0));

        // Get the webauthn struct which will be verified by the module
        bytes32 challenge = entryPoint.getUserOpHash(userOp);
        WebAuthnInfo memory webAuthn = WebAuthnUtils.getWebAuthnStruct(challenge, authenticatorData, origin);

        (bytes32 r, bytes32 s) = vm.signP256(passkeyPrivateKey, webAuthn.messageHash);

        // Format the signature data
        bytes memory pksig = abi.encode(
            WebAuthn.WebAuthnAuth({
                authenticatorData: webAuthn.authenticatorData,
                clientDataJSON: webAuthn.clientDataJSON,
                typeIndex: 1,
                challengeIndex: 23,
                r: uint256(r),
                s: uint256(s)
            })
        );
        userOp.signature = pksig;

        bytes memory validateUserOpCalldata =
            abi.encodeWithSelector(OnitSafeModule.validateUserOp.selector, userOp, challenge, 0);

        // We prank entrypoint and call like this so the safe handler context passes the _requireFromEntryPoint check
        vm.prank(entryPointAddress);
        (, bytes memory validationData) = onitAccountAddress.call(validateUserOpCalldata);

        assertEq(keccak256(validationData), keccak256(abi.encodePacked(uint256(0))));
    }

    /// -----------------------------------------------------------------------
    /// Utils
    /// -----------------------------------------------------------------------

    // Build payload which the entryPoint will call on the sender Onit 4337 account
    function buildExecutionPayload(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("executeUserOp(address,uint256,bytes,uint8)", to, value, data, uint8(0));
    }

    receive() external payable { // Allows this contract to receive ether
    }
}
