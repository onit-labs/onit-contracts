// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// 4337 imports
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import {UserOperationLib} from "account-abstraction/core/UserOperationLib.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";

// Test imports
import {AddressTestConfig} from "./AddressTestConfig.t.sol";

contract ERC4337TestConfig is AddressTestConfig {
    using UserOperationLib for PackedUserOperation;

    // Entry point
    //EntryPoint public entryPointV6;
    address internal constant ENTRY_POINT_V6 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    EntryPoint public entryPointV7;
    address internal constant ENTRY_POINT_V7 = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    uint192 internal constant BASE_NONCE_KEY = 0;
    uint256 internal constant INITIAL_BALANCE = 100 ether;

    // Default gas limits
    uint128 internal constant CALL_GAS_LIMIT = 30_000_000;
    uint128 internal constant VERIFICATION_GAS_LIMIT = 30_000_000;
    uint256 internal constant PRE_VERIFICATION_GAS = 20_000_000;
    uint128 internal constant MAX_FEE_PER_GAS = 1_000_000_000;
    uint128 internal constant MAX_PRIORITY_FEE_PER_GAS = 1_000_000_000;

    constructor() {
        vm.etch(ENTRY_POINT_V7, address(new EntryPoint()).code);
        entryPointV7 = EntryPoint(payable(ENTRY_POINT_V7));
    }

    // -----------------------------------------------------------------------
    // 4337 Helper Functions
    // -----------------------------------------------------------------------

    PackedUserOperation public userOpBase = PackedUserOperation({
        sender: address(0),
        nonce: 0,
        initCode: new bytes(0),
        callData: new bytes(0),
        accountGasLimits: bytes32(0),
        preVerificationGas: PRE_VERIFICATION_GAS,
        gasFees: bytes32(0),
        paymasterAndData: new bytes(0),
        signature: new bytes(0)
    });

    // -----------------------------------------------------------------------
    // Packed User Operation Helper Functions
    // -----------------------------------------------------------------------

    // pack uint128 into lower end of a bytes32
    function packLow128(uint128 value) internal pure returns (bytes32) {
        return bytes32(uint256(value));
    }

    // pack uint128 into upper end of a bytes32
    function packHigh128(uint128 value) internal pure returns (bytes32) {
        return bytes32(uint256(value) << 128);
    }

    // -----------------------------------------------------------------------
    // User Operation Helper Functions
    // -----------------------------------------------------------------------

    function buildUserOp(
        address sender,
        uint256 nonce,
        bytes memory initCode,
        bytes memory callData
    ) public view returns (PackedUserOperation memory userOp) {
        // Build on top of base op
        userOp = userOpBase;

        // Add sender and calldata to op
        userOp.sender = sender;
        userOp.nonce = nonce;
        userOp.initCode = initCode;
        userOp.callData = callData;
        userOp.accountGasLimits = packHigh128(VERIFICATION_GAS_LIMIT) | packLow128(CALL_GAS_LIMIT);
    }

    // // Build payload which the entryPoint will call on the sender 4337 account
    // function buildExecutionPayload(
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     Enum.Operation operation
    // ) internal pure returns (bytes memory) {
    //     return abi.encodeWithSignature("executeAndRevert(address,uint256,bytes,uint8)", to, value, data, operation);
    // }

    // function signAndFormatUserOpIndividual(
    //     PackedUserOperation memory userOp,
    //     string memory signer1
    // ) internal returns (PackedUserOperation[] memory) {
    //     userOp.signature = abi.encode(
    //         signMessageForPublicKey(signer1, Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))))
    //     );

    //     PackedUserOperation[] memory userOpArray = new PackedUserOperation[](1);
    //     userOpArray[0] = userOp;

    //     return userOpArray;
    // }

    // // Gathers signatures from signers and formats them into the signature field for the user operation
    // // Maybe only one sig is needed, so siger2 may be empty
    // function signAndFormatUserOp(
    //     UserOperation memory userOp,
    //     string memory signer1,
    //     string memory signer2
    // ) internal returns (UserOperation[] memory) {
    //     uint256 signerCount;
    //     uint256[2] memory sig1;
    //     uint256[2] memory sig2;
    //     bytes memory sigs;

    //     // Get signature for the user operation
    //     sig1 = signMessageForPublicKey(signer1, Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))));

    //     // If signer2 is not empty, get signature for it
    //     if (bytes(signer2).length > 0) {
    //         sig2 = signMessageForPublicKey(signer2,
    // Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp))));
    //         signerCount = 2;
    //     } else {
    //         signerCount = 1;
    //     }

    //     // Build the signatures into bytes
    //     /// @dev sigs is a packed bytes which represent the r and s values of the signatures
    //     /// 		- The first 64 bytes are the first signature, and so on
    //     sigs = abi.encodePacked(sig1[0], sig1[1]);
    //     if (signerCount == 2) {
    //         sigs = abi.encodePacked(sigs, abi.encodePacked(sig2[0], sig2[1]));
    //     }

    //     // Build the signer indexes
    //     /// @dev signerIndexes is a packed uint256 which encodes info about the signers
    //     /// 		- The first 8 bits are the number of signers (for these tests either 1 or 2)
    //     /// 		- The next 8 bits are the index of the first signer, and so on (shifting by 8 more bits each time)
    //     uint256 signerIndexes;
    //     if (signerCount == 1) {
    //         // Just the number of signers, since index of first signer is 0
    //         signerIndexes = uint256(1);
    //     } else {
    //         // The number of signers, the index of the first signer, and the index of the second signer
    //         signerIndexes = uint256(2);
    //         signerIndexes = signerIndexes | uint256(0) << 8;
    //         signerIndexes = signerIndexes | uint256(1) << 16;
    //     }

    //     userOp.signature = abi.encodePacked(signerIndexes, sigs);

    //     UserOperation[] memory userOpArray = new UserOperation[](1);
    //     userOpArray[0] = userOp;

    //     return userOpArray;
    // }

    // // Calculate gas used by sender of userOp
    // // ! currently only works when paymaster set to 0 - hence 'address(0) != address(0)'
    // function calculateGas(UserOperation memory userOp) internal pure returns (uint256) {
    //     uint256 mul = address(0) != address(0) ? 3 : 1;
    //     uint256 requiredGas = userOp.callGasLimit + userOp.verificationGasLimit * mul + userOp.preVerificationGas;

    //     return requiredGas * userOp.maxFeePerGas;
    // }

    // function failedOpError(uint256 opIndex, string memory reason) internal pure returns (bytes memory) {
    //     return abi.encodeWithSignature("FailedOp(uint256,string)", opIndex, reason);
    // }
}
