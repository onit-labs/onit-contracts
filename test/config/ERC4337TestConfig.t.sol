// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// 4337 imports
import {EntryPoint} from "@erc4337/core/EntryPoint.sol";
import {BaseAccount, UserOperation} from "@erc4337/core/BaseAccount.sol";

// Forum 4337 contracts
import {ForumAccount} from "../../src/erc4337-account/ForumAccount.sol";
import {ForumAccountFactory} from "../../src/erc4337-account/ForumAccountFactory.sol";
import {MemberManager} from "@utils/MemberManager.sol";

// Lib for encoding
import {Base64} from "@libraries/Base64.sol";

import "./SafeTestConfig.t.sol";
import "./BasicTestConfig.t.sol";
import {SignatureHelper} from "./SignatureHelper.t.sol";

contract ERC4337TestConfig is BasicTestConfig, SafeTestConfig, SignatureHelper {
    // Entry point
    EntryPoint public entryPoint;

    // Singleton for Forum 4337 account implementation
    ForumAccount public forumAccountSingleton;

    // Factory for individual 4337 accounts
    ForumAccountFactory public forumAccountFactory;

    // Addresses for easy use in tests
    address internal entryPointAddress;

    // Some public keys used as signers in tests
    uint256[2] internal publicKey;
    uint256[2] internal publicKey2;
    uint256[2][] internal inputMembers;

    string internal constant SIGNER_1 = "1";
    string internal constant SIGNER_2 = "2";

    string internal authentacatorData = "1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000";

    uint192 internal constant BASE_NONCE_KEY = 0;

    constructor() {
        entryPoint = new EntryPoint();
        entryPointAddress = address(entryPoint);

        // The library is deployed and called externally
        bytes memory ellipticLibraryByteCode = abi.encodePacked(vm.getCode("FCL_Elliptic_ZZ.sol:FCL_Elliptic_ZZ"));
        address ellipticAddress;
        assembly {
            ellipticAddress := create(0, add(ellipticLibraryByteCode, 0x20), mload(ellipticLibraryByteCode))
        }

        forumAccountSingleton = new ForumAccount(ellipticAddress);

        forumAccountFactory = new ForumAccountFactory(
            forumAccountSingleton,
            entryPointAddress,
            address(handler),
            hex"1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000",
            '{"type":"webauthn.get","challenge":"',
            '","origin":"https://development.forumdaos.com"}'
        );
    }

    // -----------------------------------------------------------------------
    // 4337 Helper Functions
    // -----------------------------------------------------------------------

    UserOperation public userOpBase = UserOperation({
        sender: address(0),
        nonce: 0,
        initCode: new bytes(0),
        callData: new bytes(0),
        callGasLimit: 10_000_000,
        verificationGasLimit: 20_000_000,
        preVerificationGas: 20_000_000,
        maxFeePerGas: 2,
        maxPriorityFeePerGas: 1,
        paymasterAndData: new bytes(0),
        signature: new bytes(0)
    });

    function buildUserOp(
        address sender,
        uint256 nonce,
        bytes memory initCode,
        bytes memory callData
    ) public view returns (UserOperation memory userOp) {
        // Build on top of base op
        userOp = userOpBase;

        // Add sender and calldata to op
        userOp.sender = sender;
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = callData;
    }

    // Build payload which the entryPoint will call on the sender 4337 account
    function buildExecutionPayload(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("executeAndRevert(address,uint256,bytes,uint8)", to, value, data, operation);
    }

    // !!!!! combine with the above
    function signAndFormatUserOpIndividual(
        UserOperation memory userOp,
        string memory signer1
    ) internal returns (UserOperation[] memory) {
        userOp.signature = abi.encode(
            signMessageForPublicKey(signer1, Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))))
        );

        UserOperation[] memory userOpArray = new UserOperation[](1);
        userOpArray[0] = userOp;

        return userOpArray;
    }

    // Gathers signatures from signers and formats them into the signature field for the user operation
    // Maybe only one sig is needed, so siger2 may be empty
    function signAndFormatUserOp(
        UserOperation memory userOp,
        string memory signer1,
        string memory signer2
    ) internal returns (UserOperation[] memory) {
        uint256 signerCount;
        uint256[2] memory sig1;
        uint256[2] memory sig2;
        bytes memory sigs;

        // Get signature for the user operation
        sig1 = signMessageForPublicKey(signer1, Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))));

        // If signer2 is not empty, get signature for it
        if (bytes(signer2).length > 0) {
            sig2 = signMessageForPublicKey(signer2, Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))));
            signerCount = 2;
        } else {
            signerCount = 1;
        }

        // Build the signatures into bytes
        /// @dev sigs is a packed bytes which represent the r and s values of the signatures
        /// 		- The first 64 bytes are the first signature, and so on
        sigs = abi.encodePacked(sig1[0], sig1[1]);
        if (signerCount == 2) {
            sigs = abi.encodePacked(sigs, abi.encodePacked(sig2[0], sig2[1]));
        }

        // Build the signer indexes
        /// @dev signerIndexes is a packed uint256 which encodes info about the signers
        /// 		- The first 8 bits are the number of signers (for these tests either 1 or 2)
        /// 		- The next 8 bits are the index of the first signer, and so on (shifting by 8 more bits each time)
        uint256 signerIndexes;
        if (signerCount == 1) {
            // Just the number of signers, since index of first signer is 0
            signerIndexes = uint256(1);
        } else {
            // The number of signers, the index of the first signer, and the index of the second signer
            signerIndexes = uint256(2);
            signerIndexes = signerIndexes | uint256(0) << 8;
            signerIndexes = signerIndexes | uint256(1) << 16;
        }

        userOp.signature = abi.encodePacked(signerIndexes, sigs);

        UserOperation[] memory userOpArray = new UserOperation[](1);
        userOpArray[0] = userOp;

        return userOpArray;
    }

    // Calculate gas used by sender of userOp
    // ! currently only works when paymaster set to 0 - hence 'address(0) != address(0)'
    function calculateGas(UserOperation memory userOp) internal pure returns (uint256) {
        uint256 mul = address(0) != address(0) ? 3 : 1;
        uint256 requiredGas = userOp.callGasLimit + userOp.verificationGasLimit * mul + userOp.preVerificationGas;

        return requiredGas * userOp.maxFeePerGas;
    }

    function failedOpError(uint256 opIndex, string memory reason) internal pure returns (bytes memory) {
        return abi.encodeWithSignature("FailedOp(uint256,string)", opIndex, reason);
    }
}
