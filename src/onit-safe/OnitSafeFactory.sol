// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {LibClone} from "../../lib/webauthn-sol/lib/solady/src/utils/LibClone.sol";

// Safe Module which we will deploy and set as fallback / module on our Safes
import {OnitSafe} from "./OnitSafe.sol";

// TODO consider restriction on salt and readding 'checkStartsWith'

/// @title OnitSafeProxyFactory
/// @notice Factory contract to deploy OnitSafeProxy contracts
/// @author Onit Labs
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/accounts/ERC4337Factory.sol)
contract OnitSafeProxyFactory {
    /// ----------------------------------------------------------------------------------------
    ///							FACTORY STORAGE
    /// ----------------------------------------------------------------------------------------

    error SafeInitialisationFailed();
    error OnitAccountSetupFailed();

    address public immutable compatibilityFallbackHandler;
    address public immutable safeSingletonAddress;

    /// ----------------------------------------------------------------------------------------
    ///							CONSTRUCTOR
    /// ----------------------------------------------------------------------------------------

    constructor(address _compatibilityFallbackHandler, address _safeSingletonAddress) {
        compatibilityFallbackHandler = _compatibilityFallbackHandler;
        safeSingletonAddress = _safeSingletonAddress;
    }

    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT FACTORY FUNCTIONS
    /// ----------------------------------------------------------------------------------------

    /// @dev Deploys an ERC4337 account with `salt` and returns its deterministic address.
    /// If the account is already deployed, it will simply return its address.
    /// Any `msg.value` will simply be forwarded to the account, regardless.
    function createAccount(
        uint256 passkeyPublicKeyX,
        uint256 passkeyPublicKeyY,
        uint256 salt
    ) public payable virtual returns (address) {
        // Constructor data is optional, and is omitted for easier Etherscan verification.
        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(
            msg.value, safeSingletonAddress, keccak256(abi.encodePacked(passkeyPublicKeyX, passkeyPublicKeyY, salt))
        );

        if (!alreadyDeployed) {
            // Placeholder owners since we use a passkey signer only
            address[] memory owners = new address[](1);
            owners[0] = address(0xdead);

            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owners, // set owners to the placeholder
                1, // set threshold to 1
                address(0), // no address is called on setup,
                new bytes(0), // no data is needed since we don't make a call
                compatibilityFallbackHandler,
                address(0), // no payment token is used
                0, // no payment token amount is needed
                address(0) // no payment receiver is needed
            );

            (bool success,) = account.call(initializer);
            if (!success) revert SafeInitialisationFailed();

            bytes memory setOwner =
                abi.encodeWithSignature("setupOnitSafe(uint256,uint256)", passkeyPublicKeyX, passkeyPublicKeyY);

            (success,) = account.call(setOwner);
            if (!success) revert OnitAccountSetupFailed();
        }
        return account;
    }

    /// @dev Returns the deterministic address of the account created via `createAccount`.
    /// @param salt The salt used to create the account: `keccak256(abi.encodePacked(passkeyPublicKeyX, passkeyPublicKeyY, _salt))` where _salt is some uint256
    /// @return address The deterministic address of the account
    function getAddress(bytes32 salt) public view virtual returns (address) {
        return LibClone.predictDeterministicAddressERC1967(safeSingletonAddress, salt, address(this));
    }
}
