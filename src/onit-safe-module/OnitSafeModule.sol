// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {BaseAccount, IEntryPoint} from "@erc4337/core/BaseAccount.sol";
import {PackedUserOperation} from "@erc4337/interfaces/PackedUserOperation.sol";
import {Base64} from "@libraries/Base64.sol";
import {Exec} from "@utils/Exec.sol";
import {ISafe} from "@interfaces/ISafe.sol";

/**
 * @notice ERC4337 Safe Module
 * @author Onit Labs (https://onit.fun)
 * @custom:warning This contract has not been audited, and is likely to change.
 */

/**
 * TODO
 * - add execution function
 * - fix verify sig
 */
contract OnitSafeModule is BaseAccount {
    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT STORAGE
    /// ----------------------------------------------------------------------------------------

    // Entry point allowed to call methods directly on this contract
    address internal immutable _entryPoint;

    // Public key for secp256r1 signer
    uint256[2] internal _owner;

    string public constant ACCOUNT_VERSION = "v0.2.0";

    /// @dev Values used when public key signs a message
    /// To make this variable we can pass these with the user op signature, for now we save gas writing them on deploy
    struct SigningData {
        bytes authData;
        string clientDataStart;
        string clientDataEnd;
    }

    SigningData public signingData;

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
     * Execute a call but also revert if the execution fails.
     * The default behavior of the Safe is to not revert if the call fails,
     * which is challenging for integrating with ERC4337 because then the
     * EntryPoint wouldn't know to emit the UserOperationRevertReason event,
     * which the frontend/client uses to capture the reason for the failure.
     */
    // function executeAndRevert(
    //     address to,
    //     uint256 value,
    //     bytes memory data,
    //     Enum.Operation operation
    // ) external payable {
    //     _requireFromEntryPoint();

    //     bool success = execute(to, value, data, operation, type(uint256).max);

    //     bytes memory returnData = Exec.getReturnData(type(uint256).max);
    //     // Revert with the actual reason string
    //     // Adopted from: https://github.com/Uniswap/v3-periphery/blob/464a8a49611272f7349c970e0fadb7ec1d3c1086/contracts/base/Multicall.sol#L16-L23
    //     if (!success) {
    //         if (returnData.length < 68) revert();
    //         assembly {
    //             returnData := add(returnData, 0x04)
    //         }
    //         revert(abi.decode(returnData, (string)));
    //     }
    // }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return IEntryPoint(_entryPoint);
    }

    function owner() public view virtual returns (uint256[2] memory) {
        return _owner;
    }

    /// ----------------------------------------------------------------------------------------
    ///							INTERNAL METHODS
    /// ----------------------------------------------------------------------------------------

    // TODO consider nonce validation in here as well in on v6 entrypoint

    /**
     * @notice Validate the signature of the user operation
     * @param userOp The user operation to validate
     * @param userOpHash The hash of the user operation
     * @return sigTimeRange The time range the signature is valid for
     * @dev This is a first take at getting the signature validation working using passkeys
     * - The signature may be validated using a domain seperator
     * - More efficient validation of the hashing and conversion of authData is needed
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 sigTimeRange) {
        return 0;
    }
}
