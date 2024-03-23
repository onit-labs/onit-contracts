// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {LibClone} from "../../lib/webauthn-sol/lib/solady/src/utils/LibClone.sol";

// Safe Module which we will deploy and set as fallback / module on our Safes
import {OnitSafe} from "./OnitSafe.sol";

import "forge-std/console.sol";

/// @title OnitSafeProxyFactory
/// @notice Factory contract to deploy OnitSafeProxy contracts
/// @author Onit Labs
/// @author modified from Solady (https://github.com/Vectorized/solady/blob/main/src/accounts/ERC4337Factory.sol)
contract OnitSafeProxyFactory {
    address public immutable compatibilityFallbackHandler;
    address public immutable safeSingletonAddress;

    constructor(address _compatibilityFallbackHandler, address _safeSingletonAddress) {
        compatibilityFallbackHandler = _compatibilityFallbackHandler;
        safeSingletonAddress = _safeSingletonAddress;
    }

    /// @dev Deploys an ERC4337 account with `salt` and returns its deterministic address.
    /// If the account is already deployed, it will simply return its address.
    /// Any `msg.value` will simply be forwarded to the account, regardless.
    function createAccount(uint256[2] memory passkeyPublicKey, bytes32 salt) public payable virtual returns (address) {
        // TODO consider checkstartswith here
        // Check that the salt is tied to the owner if required, regardless.
        //LibClone.checkStartsWith(salt, owner);

        // Constructor data is optional, and is omitted for easier Etherscan verification.
        (bool alreadyDeployed, address account) =
            LibClone.createDeterministicERC1967(msg.value, safeSingletonAddress, salt);

        // Placeholder owners since we use a passkey signer only
        address[] memory owners = new address[](1);
        owners[0] = address(0xdead);

        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners,
            1,
            address(0), // compatibilityFallbackHandler,
            new bytes(0), //abi.encodeWithSignature("enableModules(address[])", modules),
            compatibilityFallbackHandler,
            address(0),
            0,
            address(0)
        );

        if (!alreadyDeployed) {
            account.call(initializer);

            bytes memory setOwner = abi.encodeWithSignature("setupOnitSafe(uint256[2])", passkeyPublicKey);
            account.call(setOwner);

            // TODO setup onit signers

            /// @solidity memory-safe-assembly
            // assembly {
            //     mstore(0x14, owner) // Store the `owner` argument.
            //     mstore(0x00, 0xc4d66de8000000000000000000000000) // `initialize(address)`.
            //     if iszero(call(gas(), account, 0, 0x10, 0x24, codesize(), 0x00)) {
            //         returndatacopy(mload(0x40), 0x00, returndatasize())
            //         revert(mload(0x40), returndatasize())
            //     }
            // }
        }
        return account;
    }

    /// @dev Returns the deterministic address of the account created via `createAccount`.
    function getAddress(bytes32 salt) public view virtual returns (address) {
        return LibClone.predictDeterministicAddressERC1967(safeSingletonAddress, salt, address(this));
    }
}
