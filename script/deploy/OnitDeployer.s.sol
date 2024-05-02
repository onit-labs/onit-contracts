// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {OnitAccount} from "../../src/onit-account/OnitAccount.sol";
import {OnitAccountProxyFactory} from "../../src/onit-account/OnitAccountFactory.sol";

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
        address onitAccount;
        address onitAccountProxyFactory;

        bytes32 ONIT_SAFE_SALT = keccak256(abi.encode("onit-account", ONIT_SAFE_VERSION, ONIT_SAFE_NONCE));
        bytes32 ONIT_SAFE_PROXY_FACTORY_SALT = keccak256(
            abi.encode("onit-account-proxy-factory", ONIT_SAFE_PROXY_FACTORY_VERSION, ONIT_SAFE_PROXY_FACTORY_NONCE)
        );

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes memory onitAccountInitCode = type(OnitAccount).creationCode;

        assembly {
            onitAccount := create2(0, add(onitAccountInitCode, 0x20), mload(onitAccountInitCode), ONIT_SAFE_SALT)
        }

        bytes memory onitAccountProxyFactoryInitCode = abi.encodePacked(
            type(OnitAccountProxyFactory).creationCode, abi.encode(COMPATIBILITY_FALLBACK_HANDLER, onitAccount)
        );

        assembly {
            onitAccountProxyFactory :=
                create2(
                    0,
                    add(onitAccountProxyFactoryInitCode, 0x20),
                    mload(onitAccountProxyFactoryInitCode),
                    ONIT_SAFE_PROXY_FACTORY_SALT
                )
        }

        console2.log("Onit Safe: ", onitAccount);
        console2.log("Onit Safe Factory: ", onitAccountProxyFactory);

        vm.stopBroadcast();
    }
}
