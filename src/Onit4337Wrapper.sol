// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {IEntryPoint, PackedUserOperation} from "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {UUPSUpgradeable} from "../lib/webauthn-sol/lib/solady/src/utils/UUPSUpgradeable.sol";

/**
 * TODO
 * - consider execute functions given this contract will be inherited by the safe OR a module/fallback
 * - more advanced nonce management (out of order, session keys etc)
 */

/**
 * @notice Onit ERC4337 Wrapper
 * @author Onit Labs (https://onit.fun)
 * @author Modified from https://github.com/vectorized/solady/main/src/accounts/ERC4337.sol
 * @author Infinitism https://github.com/eth-infinitism/account-abstraction/develop/contracts/samples/SimpleAccount.sol
 * @dev An adaptation of the v0.7.0 ERC4337 Base Account. Intended to be inherited and constructed into an account elsewhere
 * @custom:warning This contract has not been audited, and is likely to change.
 */
abstract contract Onit4337Wrapper is UUPSUpgradeable {
    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT STORAGE
    /// ----------------------------------------------------------------------------------------

    error NotFromEntryPoint();

    // V0.7.0 entrypoint
    address internal constant ENTRY_POINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    // Secp256r1 public key signer
    uint256[2] internal _owner;

    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT LOGIC
    /// ----------------------------------------------------------------------------------------

    /// @notice Validates a user operation provided by the entry point.
    /// @param userOp The user operation to validate
    /// @param userOpHash The hash of the user operation
    /// @param missingAccountFunds The amount of funds missing in the account
    /// @return validationData The validation data, detailed in _validateSignature
    /// @dev Implementation should provide some _validateSignature logic
    ///
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external virtual returns (uint256 validationData);

    /// @notice Execute the given call from this account.
    /// @param target The target call address.
    /// @param value  The call value to user.
    /// @param data   The raw call data.
    /// @return result The result of the call.
    ///
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) public payable virtual returns (bytes memory result) {
        _requireFromEntryPoint();

        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, data.offset, data.length)
            if iszero(call(gas(), target, value, result, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    /// @notice Execute a delegatecall with `delegate` on this account.
    /// @param delegate The delegate call address.
    /// @param data The raw call data.
    /// @return result The result of the delegate call.
    ///
    function delegateExecute(
        address delegate,
        bytes calldata data
    ) public payable virtual delegateExecuteGuard returns (bytes memory result) {
        _requireFromEntryPoint();

        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            calldatacopy(result, data.offset, data.length)
            // Forwards the `data` to `delegate` via delegatecall.
            if iszero(delegatecall(gas(), delegate, result, data.length, codesize(), 0x00)) {
                // Bubble up the revert if the call reverts.
                returndatacopy(result, 0x00, returndatasize())
                revert(result, returndatasize())
            }
            mstore(result, returndatasize()) // Store the length.
            let o := add(result, 0x20)
            returndatacopy(o, 0x00, returndatasize()) // Copy the returndata.
            mstore(0x40, add(o, returndatasize())) // Allocate the memory.
        }
    }

    // TODO batch execute function

    /// @notice Return the owner of this account.
    /// @return The public key of the owner of this account
    ///
    function owner() external view virtual returns (uint256[2] memory) {
        return _owner;
    }

    /// @notice Return the entryPoint used by this account.
    /// @return The v0.7.0 entry point
    ///
    function entryPoint() public view virtual returns (IEntryPoint) {
        return IEntryPoint(ENTRY_POINT);
    }

    /// @notice Return the account nonce.
    /// @dev This method returns the next sequential nonce.
    ///      For a nonce of a specific key, use `entrypoint.getNonce(account, key)`
    /// @return The nonce of this account
    ///
    function getNonce() public view virtual returns (uint256) {
        return entryPoint().getNonce(address(this), 0);
    }

    /// ----------------------------------------------------------------------------------------
    ///							INTERNAL METHODS
    /// ----------------------------------------------------------------------------------------

    /**
     * Ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal view virtual {
        if (msg.sender != address(entryPoint())) revert NotFromEntryPoint();
    }

    /**
     * Validate the nonce of the UserOperation.
     * This method may validate the nonce requirement of this account.
     * e.g.
     * To limit the nonce to use sequenced UserOps only (no "out of order" UserOps):
     *      `require(nonce < type(uint64).max)`
     * For a hypothetical account that *requires* the nonce to be out-of-order:
     *      `require(nonce & type(uint64).max == 0)`
     *
     * The actual nonce uniqueness is managed by the EntryPoint, and thus no other
     * action is needed by the account itself.
     *
     * @param nonce to validate
     *
     * solhint-disable-next-line no-empty-blocks
     */
    function _validateNonce(uint256 nonce) internal view virtual;

    /// @dev Sends to the EntryPoint (i.e. `msg.sender`) the missing funds for this transaction.
    /// Subclass MAY override this modifier for better funds management.
    /// (e.g. send to the EntryPoint more than the minimum required, so that in future transactions
    /// it will not be required to send again)
    ///
    /// `missingAccountFunds` is the minimum value this modifier should send the EntryPoint,
    /// which MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    /// @dev Modified from https://github.com/vectorized/solady/main/src/accounts/ERC4337.sol
    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if missingAccountFunds {
                // Ignore failure (it's EntryPoint's job to verify, not the account's).
                pop(call(gas(), caller(), missingAccountFunds, codesize(), 0x00, codesize(), 0x00))
            }
        }
    }

    /// @dev Ensures that the owner and implementation slots' values aren't changed.
    /// You can override this modifier to ensure the sanctity of other storage slots too.
    modifier delegateExecuteGuard() virtual {
        bytes32 implementationSlotValue;
        /// @solidity memory-safe-assembly
        assembly {
            implementationSlotValue := sload(_ERC1967_IMPLEMENTATION_SLOT)
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(eq(implementationSlotValue, sload(_ERC1967_IMPLEMENTATION_SLOT))) { revert(codesize(), 0x00) }
        }
    }
}
