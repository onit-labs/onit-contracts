// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {WebAuthn} from "@webauthn-sol/WebAuthn.sol";
import {Safe} from "safe-contracts/Safe.sol"; // ! warning tmp import

import {Onit4337Wrapper, PackedUserOperation} from "../Onit4337Wrapper.sol";
import {ERC1271} from "@utils/ERC1271.sol";

/**
 * @notice ERC4337 Safe Account with passkey signer
 * @author Onit Labs (https://onit.fun)
 * @custom:warning This contract has not been audited, and is likely to change.
 */
contract OnitAccount is Safe, Onit4337Wrapper, ERC1271 {
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

    function setupOnitAccount(uint256 ownerX, uint256 ownerY) public {
        if (_owner[0] != 0 || _owner[1] != 0) {
            revert AlreadyInitialized();
        }

        // Set the owner of the implementation contract so it can not be initialized again
        _owner = [ownerX, ownerY];
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

    /// ----------------------------------------------------------------------------------------
    ///							LEGACY EIP-1271 METHOD
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Legacy EIP-1271 signature validation method.
     * @dev Implementation of ISignatureValidator (see Safe `interfaces/ISignatureValidator.sol`)
     * @param _data Arbitrary length data signed on the behalf of address(msg.sender).
     * @param _signature Signature byte array associated with _data.
     * @return The Legacy EIP-1271 magic value: bytes4(keccak256("isValidSignature(bytes,bytes)") = 0x20c13b0b
     */
    function isValidSignature(bytes memory _data, bytes calldata _signature) public view returns (bytes4) {
        bytes32 messageHash = replaySafeHash(keccak256(_data));

        if (_signature.length == 0) {
            require(signedMessages[messageHash] != 0, "Hash not approved");
        } else {
            require(_validateSignature(messageHash, _signature), "Invalid signature");
        }
        return EIP1271_MAGIC_VALUE;
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

    /**
     * @inheritdoc Onit4337Wrapper
     * @dev Not used yet, implemented to complete abstract contract
     */
    function _validateNonce(uint256 nonce) internal view virtual override {}

    /// @inheritdoc ERC1271
    function _domainNameAndVersion() internal pure override(ERC1271) returns (string memory, string memory) {
        return ("OnitAccount", "0.0.2");
    }

    /// @dev To ensure that only the owner or the account itself can upgrade the implementation.
    function _authorizeUpgrade(address) internal virtual override {
        _requireFromEntryPoint();
    }
}
