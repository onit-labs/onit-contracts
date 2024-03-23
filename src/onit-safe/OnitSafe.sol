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

    /**
     * @notice Constructor
     * @dev Ensures that this contract can only be used as a singleton for Proxy contracts
     */
    constructor() Safe() {
        // The implementation should not be setup so we set owner to prevent it
        _owner = [1, 1];
    }

    function setupOnitSafe(uint256[2] memory setupOwner) public {
        if (_owner[0] != 0 || _owner[1] != 0) {
            revert AlreadyInitialized();
        }

        // Set the owner of the implementation contract so it can not be initialized again
        _owner = setupOwner;
    }

    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT LOGIC
    /// ----------------------------------------------------------------------------------------

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual override returns (uint256 validationData) {
        _requireFromEntryPoint();

        // Validate the signature
        return _validateSignature(userOp, userOpHash);

        _payPrefund(missingAccountFunds);
    }

    function execute(
        address target,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable virtual override {
        // Execute the call
        // TODO use safe execution fn here?
        _call(target, value, data);
    }
    /// ----------------------------------------------------------------------------------------
    ///							INTERNAL METHODS
    /// ----------------------------------------------------------------------------------------

    // TODO consider nonce validation in here as well in on v6 entrypoint

    /**
     * @inheritdoc Onit4337Wrapper
     * @dev Validate the user signed the user operation.
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

    /**
     * @inheritdoc Onit4337Wrapper
     * @dev Not used yet, implemented to complete abstract contract
     */
    function _validateNonce(uint256 nonce) internal view virtual override {
        // TODO
    }
}
