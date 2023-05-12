// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script2} from "../../lib/foundry-deployment-manager/src/utils/Script2.sol";

import {console} from "forge-std/console.sol";

contract FclEllipticDeployer is Script2 {
    function run() public {
        address localBroadcaster;
        address contractAddress;
        string memory chainName;

        // TODO improve this
        if (block.chainid == 137) {
            chainName = "POLYGON";
        } else if (block.chainid == 80001) {
            chainName = "MUMBAI";
        }

        string memory pkEnvVar = string.concat(chainName, "_PRIVATE_KEY");
        try vm.envUint(pkEnvVar) returns (uint256 key) {
            localBroadcaster = vm.rememberKey(key);
        } catch {
            console.log("%s key not found or not parseable as uint", pkEnvVar);
        }

        vm.startBroadcast(localBroadcaster);

        // No longer using external validator
        bytes memory deploymentBytecode = vm.getCode("FCL_Elliptic_ZZ.sol:FCL_Elliptic_ZZ");

        console.logBytes(deploymentBytecode);

        assembly {
            contractAddress := create2(0, add(deploymentBytecode, 0x20), mload(deploymentBytecode), 0)
        }

        vm.stopBroadcast();

        console.log("Elliptic library deployed at %s", contractAddress);
    }
}
