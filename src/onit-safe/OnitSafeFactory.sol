// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// Factory for deploying Safes
import "safe-smart-account/contracts/proxies/SafeProxyFactory.sol";

// Safe Module which we will deploy and set as fallback / module on our Safes
import {OnitSafe} from "./OnitSafe.sol";

contract OnitSafeFactory {
    SafeProxyFactory public proxyFactory;

    address public immutable addModulesLibAddress;
    address public immutable safeSingletonAddress;
    address public immutable entryPointAddress;

    constructor(
        address _proxyFactoryAddress,
        address _addModulesLibAddress,
        address _safeSingletonAddress,
        address _entryPointAddress
    ) {
        proxyFactory = SafeProxyFactory(_proxyFactoryAddress);

        addModulesLibAddress = _addModulesLibAddress;
        safeSingletonAddress = _safeSingletonAddress;
        entryPointAddress = _entryPointAddress;
    }

    /**
     * @notice Deploys a Safe with a OnitSafeModule and a passkey signer
     * @param passkeyPublicKey The public key of the passkey signer
     * @dev See https://github.com/safe-global/safe-modules/modules/4337/README.md for explaination of this initialisation
     */
    function createOnitSafe(
        uint256[2] memory passkeyPublicKey,
        uint256 nonce
    ) public returns (address payable onitAccountAddress) {
        // Deploy module with passkey signer
        OnitSafe safe4337Module = new OnitSafe();

        address[] memory modules = new address[](1);
        modules[0] = address(safe4337Module);

        // Placeholder owners since we use a passkey signer only
        address[] memory owners = new address[](1);
        owners[0] = address(0xdead);

        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            owners,
            1,
            addModulesLibAddress,
            abi.encodeWithSignature("enableModules(address[])", modules),
            address(safe4337Module),
            address(0),
            0,
            address(0)
        );

        onitAccountAddress = payable(proxyFactory.createProxyWithNonce(safeSingletonAddress, initializer, nonce));
    }
}
