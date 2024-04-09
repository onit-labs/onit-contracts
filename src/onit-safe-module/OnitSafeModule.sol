// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {BaseAccount, IEntryPoint} from "../../lib/account-abstraction/contracts/core/BaseAccount.sol";
import {PackedUserOperation} from "../../lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HandlerContext} from "../../lib/safe-smart-account/contracts/handler/HandlerContext.sol";
import {WebAuthn} from "../../lib/webauthn-sol/src/WebAuthn.sol";

import {ISafe} from "../../src/interfaces/ISafe.sol";

import "../../lib/forge-std/src/console.sol";

/**
 * @notice ERC4337 Safe Module
 * @author Onit Labs (https://onit.fun)
 * @custom:warning This contract has not been audited, and is likely to change.
 */
contract OnitSafeModule is BaseAccount, HandlerContext {
    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT STORAGE
    /// ----------------------------------------------------------------------------------------

    error NotFromEntryPoint();

    // Entry point allowed to call methods directly on this contract
    address internal immutable _entryPoint;

    // Public key for secp256r1 signer
    uint256[2] internal _owner;

    string public constant ACCOUNT_VERSION = "v0.2.0";

    /// ----------------------------------------------------------------------------------------
    ///							CONSTRUCTOR
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Constructor
     */
    constructor(address constructorEntryPoint, uint256[2] memory constructorOwner) {
        _entryPoint = constructorEntryPoint;

        _owner = constructorOwner;
    }

    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT LOGIC
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Validates a user operation provided by the entry point.
     * @dev Modified from Safe 4337 example module
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external override returns (uint256 validationData) {
        _requireFromEntryPoint();

        address payable safeAddress = payable(userOp.sender);
        // The entry point address is appended to the calldata in `HandlerContext` contract
        // Because of this, the relayer may manipulate the entry point address, therefore we have to verify that
        // the sender is the Safe specified in the userOperation
        require(safeAddress == msg.sender, "Invalid caller");

        /// TODO consider restriction on what the account can call

        // The userOp nonce is validated in the entry point (for 0.6.0+), therefore we will not check it again
        validationData = _validateSignature(userOp, userOpHash);

        // We trust the entry point to set the correct prefund value, based on the operation params
        // We need to perform this even if the signature is not valid, else the simulation function of the entry point will not work.
        if (missingAccountFunds != 0) {
            // We intentionally ignore errors in paying the missing account funds, as the entry point is responsible for
            // verifying the prefund has been paid. This behaviour matches the reference base account implementation.
            ISafe(safeAddress).execTransactionFromModule(_entryPoint, missingAccountFunds, "", 0);
        }
    }

    /**
     * @notice Executes a user operation provided by the entry point.
     * @param to Destination address of the user operation.
     * @param value Ether value of the user operation.
     * @param data Data payload of the user operation.
     * @param operation Operation type of the user operation.
     */
    function executeUserOp(address to, uint256 value, bytes memory data, uint8 operation) external {
        _requireFromEntryPoint();

        require(ISafe(msg.sender).execTransactionFromModule(to, value, data, operation), "Execution failed");
    }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return IEntryPoint(_entryPoint);
    }

    function owner() public view virtual returns (uint256[2] memory) {
        return _owner;
    }

    /// ----------------------------------------------------------------------------------------
    ///							INTERNAL METHODS
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Require that the call is from the entry point
     * @dev Modified from reference 4337 account to take _msgSender() from the Safe handler context
     */
    function _requireFromEntryPoint() internal view virtual override {
        if (_msgSender() != _entryPoint) revert NotFromEntryPoint();
    }

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
            x: owner()[0],
            y: owner()[1]
        }) ? 0 : 1;
    }
}
