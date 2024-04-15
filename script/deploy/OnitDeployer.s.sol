// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {OnitSafe} from "../../src/onit-safe/OnitSafe.sol";
import {OnitSafeProxyFactory} from "../../src/onit-safe/OnitSafeFactory.sol";

import {Script, console2} from "forge-std/Script.sol";

/**
 * @notice Deploy the Onit Safe and the Onit Safe Proxy Factory
 */
contract OnitDeployer is Script {
    address public constant COMPATIBILITY_FALLBACK_HANDLER = address(0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99);

    string public constant ONIT_SAFE_VERSION = "0.0.1";
    uint256 public constant ONIT_SAFE_NONCE = 1;

    string public constant ONIT_SAFE_PROXY_FACTORY_VERSION = "0.0.1";
    uint256 public constant ONIT_SAFE_PROXY_FACTORY_NONCE = 1;

    function setUp() public {}

    function run() public {
        address onitSafe;
        address onitSafeProxyFactory;

        bytes32 ONIT_SAFE_SALT = keccak256(abi.encode("onit-safe", ONIT_SAFE_VERSION, ONIT_SAFE_NONCE));
        bytes32 ONIT_SAFE_PROXY_FACTORY_SALT = keccak256(
            abi.encode("onit-safe-proxy-factory", ONIT_SAFE_PROXY_FACTORY_VERSION, ONIT_SAFE_PROXY_FACTORY_NONCE)
        );

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes memory onitSafeInitCode = type(OnitSafe).creationCode;

        assembly {
            onitSafe := create2(0, add(onitSafeInitCode, 0x20), mload(onitSafeInitCode), ONIT_SAFE_SALT)
        }

        bytes memory onitSafeProxyFactoryInitCode = abi.encodePacked(
            type(OnitSafeProxyFactory).creationCode, abi.encode(COMPATIBILITY_FALLBACK_HANDLER, onitSafe)
        );

        assembly {
            onitSafeProxyFactory :=
                create2(
                    0,
                    add(onitSafeProxyFactoryInitCode, 0x20),
                    mload(onitSafeProxyFactoryInitCode),
                    ONIT_SAFE_PROXY_FACTORY_SALT
                )
        }

        console2.log("Onit Safe: ", onitSafe);
        console2.log("Onit Safe Factory: ", onitSafeProxyFactory);

        vm.stopBroadcast();
    }
}
