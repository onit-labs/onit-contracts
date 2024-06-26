// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {LibClone} from "../../lib/webauthn-sol/lib/solady/src/utils/LibClone.sol";

import {OnitAccount} from "./OnitAccount.sol";

/// @title OnitAccountProxyFactory
/// @notice Factory contract to deploy OnitAccountProxy contracts
/// @author Onit Labs
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/accounts/ERC4337Factory.sol)
contract OnitAccountProxyFactory {
    /// ----------------------------------------------------------------------------------------
    ///							FACTORY STORAGE
    /// ----------------------------------------------------------------------------------------

    error SafeInitialisationFailed();
    error OnitAccountSetupFailed();

    address public immutable compatibilityFallbackHandler;
    address public immutable onitAccountSingletonAddress;

    /// ----------------------------------------------------------------------------------------
    ///							CONSTRUCTOR
    /// ----------------------------------------------------------------------------------------

    constructor(address _compatibilityFallbackHandler, address _onitAccountSingletonAddress) {
        compatibilityFallbackHandler = _compatibilityFallbackHandler;
        onitAccountSingletonAddress = _onitAccountSingletonAddress;
    }

    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT FACTORY FUNCTIONS
    /// ----------------------------------------------------------------------------------------

    /// @dev Deploys an ERC4337 account and returns its deterministic address.
    /// If the account is already deployed, it will simply return its address.
    /// Any `msg.value` will simply be forwarded to the account, regardless.
    /// @param passkeyPublicKeyX The x-coordinate of the passkey public key
    /// @param passkeyPublicKeyY The y-coordinate of the passkey public key
    /// @param salt A salt which will combine with the public key to create a deterministic address
    /// @return account The address of the deployed account
    ///
    function createAccount(
        uint256 passkeyPublicKeyX,
        uint256 passkeyPublicKeyY,
        uint256 salt
    ) public payable virtual returns (address) {
        // Constructor data is optional, and is omitted for easier Etherscan verification.
        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(
            msg.value,
            onitAccountSingletonAddress,
            keccak256(abi.encodePacked(passkeyPublicKeyX, passkeyPublicKeyY, salt))
        );

        if (!alreadyDeployed) {
            /**
             *  The below call is required to setup the Safe on which the Onit account is built
             *  The hex value corresponds to the following:
             *
             *  bytes memory initializer = abi.encodeWithSignature(
             *      "setup(address[],uint256,address,bytes,address,address,uint256,address)",
             *      [address(0xdead)], // set owners to the placeholder
             *      1, // set threshold to 1
             *      address(0), // no address is called on setup,
             *      new bytes(0), // no data is needed since we don't make a call
             *      compatibilityFallbackHandler,
             *      address(0), // no payment token is used
             *      0, // no payment token amount is needed
             *      address(0) // no payment receiver is needed
             *  );
             */
            (bool success,) = account.call(
                abi.encodePacked(
                    hex"b63e800d0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000140000000000000000000000000",
                    compatibilityFallbackHandler,
                    hex"0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000dead0000000000000000000000000000000000000000000000000000000000000000"
                )
            );
            if (!success) revert SafeInitialisationFailed();

            bytes memory setOwner =
                abi.encodeWithSelector(OnitAccount.setupOnitAccount.selector, passkeyPublicKeyX, passkeyPublicKeyY);

            (success,) = account.call(setOwner);
            if (!success) revert OnitAccountSetupFailed();
        }
        return account;
    }

    /// @dev Returns the deterministic address of the account created via `createAccount`.
    /// @param salt The salt used to create the account: `keccak256(abi.encodePacked(passkeyPublicKeyX,
    /// passkeyPublicKeyY, _salt))` where _salt is some uint256
    /// @return address The deterministic address of the account
    function getAddress(bytes32 salt) public view virtual returns (address) {
        return LibClone.predictDeterministicAddressERC1967(onitAccountSingletonAddress, salt, address(this));
    }

    /// @dev Returns the initialization code hash of the ERC4337 account (a minimal ERC1967 proxy).
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash() public view virtual returns (bytes32) {
        return LibClone.initCodeHashERC1967(onitAccountSingletonAddress);
    }
}
