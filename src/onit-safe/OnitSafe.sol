// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {Safe} from "../../lib/safe-smart-account/contracts/Safe.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Onit4337Wrapper, PackedUserOperation} from "../Onit4337Wrapper.sol";

import "../../lib/forge-std/src/console.sol";

/**
 * @notice ERC4337 Safe Account
 * @author Onit Labs (https://onit.fun)
 * @custom:warning This contract has not been audited, and is likely to change.
 */
contract OnitSafe is Safe, Onit4337Wrapper {
    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT STORAGE
    /// ----------------------------------------------------------------------------------------

    error AlreadyInitialized();

    /// ----------------------------------------------------------------------------------------
    ///							CONSTRUCTOR
    /// ----------------------------------------------------------------------------------------

    function setupOnitSafe(uint256[2] memory setupOwner) public {
        // Set the owner of the implementation contract so it can not be initialized again
        _owner = setupOwner;

        // super.setup();
    }

    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT LOGIC
    /// ----------------------------------------------------------------------------------------

    /// ----------------------------------------------------------------------------------------
    ///							INTERNAL METHODS
    /// ----------------------------------------------------------------------------------------

    // TODO consider nonce validation in here as well in on v6 entrypoint

    /**
     * @notice Validate the signature of the user operation
     * @param userOp The user operation to validate
     * @param userOpHash The hash of the user operation
     * @return sigTimeRange The time range the signature is valid for
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 sigTimeRange) {
        WebAuthn.WebAuthnAuth memory auth = abi.decode(userOp.signature, (WebAuthn.WebAuthnAuth));

        return WebAuthn.verify({
            challenge: abi.encodePacked(userOpHash),
            requireUV: false,
            webAuthnAuth: auth,
            x: _owner[0],
            y: _owner[1]
        }) ? 0 : 1;
    }
}
