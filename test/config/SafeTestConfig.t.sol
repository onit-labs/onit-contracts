// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Take care that version of Safe in SafeTestTools .gitmodule matches ours
import {
    CompatibilityFallbackHandler,
    Enum,
    Safe,
    SafeInstance,
    SafeProxyFactory,
    SafeTestTools,
    SignMessageLib
} from "safe-tools/SafeTestTools.sol";

import {MultiSend} from "safe-contracts/libraries/MultiSend.sol";

// General setup helper for all safe contracts
contract SafeTestConfig is SafeTestTools {
    MultiSend internal multisend;
    SignMessageLib internal signMessageLib;

    // Used to store the address of the safe created in tests
    address internal safeAddress;

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    constructor() {
        multisend = new MultiSend();
        signMessageLib = new SignMessageLib();
    }

    /// -----------------------------------------------------------------------
    /// Utils
    /// -----------------------------------------------------------------------

    function buildSafeMultisend(
        Enum.Operation operation,
        address to,
        uint256 value,
        bytes memory data
    ) internal pure returns (bytes memory) {
        // Encode the multisend transaction
        // (needed to delegate call from the safe as addModule is 'authorised')
        bytes memory tmp = abi.encodePacked(operation, to, value, uint256(data.length), data);

        // Create multisend payload
        return abi.encodeWithSignature("multiSend(bytes)", tmp);
    }
}
