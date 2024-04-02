// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {Safe} from "../../lib/safe-smart-account/contracts/Safe.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";
import {Onit4337Wrapper, PackedUserOperation} from "../Onit4337Wrapper.sol";
import {ERC1271} from "../utils/ERC1271.sol";

import "../../lib/forge-std/src/console.sol";

/**
 * @notice ERC4337 Safe Account
 * @author Onit Labs (https://onit.fun)
 * @custom:warning This contract has not been audited, and is likely to change.
 */
contract OnitSafe is Safe, Onit4337Wrapper, ERC1271 {
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

    /// @notice Custom implemenentation of the ERC-4337 `validateUserOp` method. The EntryPoint will
    ///         make the call to the recipient only if this validation call returns successfully.
    ///         See `IAccount.validateUserOp()`.
    ///
    /// @dev Signature failure should be reported by returning 1 (see: `_validateSignature()`). This
    ///      allows making a "simulation call" without a valid signature. Other failures (e.g. nonce
    ///      mismatch, or invalid signature format) should still revert to signal failure.
    /// @dev Reverts if the signature verification fails (except for the case mentionned earlier).
    ///
    /// @param userOp              The `UserOperation` to validate.
    /// @param userOpHash          The `UserOperation` hash (including the chain ID).
    /// @param missingAccountFunds The missing account funds that must be deposited on the Entrypoint.
    ///
    /// @return validationData The encoded `ValidationData` structure
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual override returns (uint256 validationData) {
        _requireFromEntryPoint();

        validationData = _validateSignature(userOpHash, userOp.signature) ? 0 : 1;

        _payPrefund(missingAccountFunds);
    }

    /// @notice Execute a call from this account
    ///
    /// @param target contract address to call
    /// @param value value to send
    /// @param data to be executed on the target contract
    /// @param operation type of operation (CALL, DELEGATECALL)
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

    /// @inheritdoc ERC1271
    ///
    /// @dev Used both for classic ERC-1271 signature AND `UserOperation` validations.
    /// @dev Reverts if the signature does not correspond to an ERC-1271 signature or to the abi
    ///      encoded version of a `WebAuthnAuth` struct.
    /// @dev Does NOT revert if the signature verification fails to allow making a "simulation call"
    ///      without a valid signature.
    ///
    /// @param message   The message whose signature has been performed on
    /// @param signature The abi encoded `SignatureWrapper` struct
    function _validateSignature(bytes32 message, bytes calldata signature) internal view override returns (bool) {
        return WebAuthn.verify({
            challenge: abi.encodePacked(message),
            requireUV: false,
            webAuthnAuth: abi.decode(signature, (WebAuthn.WebAuthnAuth)),
            x: _owner[0],
            y: _owner[1]
        });
    }

    // /**
    //  * @inheritdoc Onit4337Wrapper
    //  * @dev Validate the user signed the user operation.
    //  */
    // function _validateSignature(
    //     PackedUserOperation calldata userOp,
    //     bytes32 userOpHash
    // ) internal virtual override returns (uint256 sigTimeRange) {
    //     WebAuthn.WebAuthnAuth memory auth = abi.decode(userOp.signature, (WebAuthn.WebAuthnAuth));

    //     return WebAuthn.verify({
    //         challenge: abi.encodePacked(userOpHash),
    //         requireUV: false,
    //         webAuthnAuth: auth,
    //         x: _owner[0],
    //         y: _owner[1]
    //     }) ? 0 : 1;
    // }

    /**
     * @inheritdoc Onit4337Wrapper
     * @dev Not used yet, implemented to complete abstract contract
     */
    function _validateNonce(uint256 nonce) internal view virtual override {
        // TODO
    }

    // TODO
    function _domainNameAndVersion() internal view override(ERC1271) returns (string memory, string memory) {}

    /// @dev To ensure that only the owner or the account itself can upgrade the implementation.
    function _authorizeUpgrade(address) internal virtual override {
        _requireFromEntryPoint();
    }
}
