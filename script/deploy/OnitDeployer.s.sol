// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.23;

import {OnitSafe} from "../../src/onit-safe/OnitSafe.sol";
import {OnitSafeProxyFactory} from "../../src/onit-safe/OnitSafeFactory.sol";

import {Script, console2} from "forge-std/Script.sol";

/**
 * @notice Deploy the Onit Safe and the Onit Safe Proxy Factory
 */
contract OnitDeployer is Script {
    OnitSafe public onitSafe;
    OnitSafeProxyFactory public onitSafeFactory;

    address public constant COMPATIBILITY_FALLBACK_HANDLER = address(0xfd0732Dc9E303f09fCEf3a7388Ad10A83459Ec99);

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // This implementation which will be deployed as a proxy
        onitSafe = new OnitSafe();

        // The factory which will deploy the proxies
        onitSafeFactory = new OnitSafeProxyFactory(COMPATIBILITY_FALLBACK_HANDLER, address(onitSafe));

        console2.log("Onit Safe: ", address(onitSafe));
        console2.log("Onit Safe Factory: ", address(onitSafeFactory));
    }
}
