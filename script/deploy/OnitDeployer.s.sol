// // SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {SafeSingletonDeployer} from "safe-singleton-deployer-sol/src/SafeSingletonDeployer.sol";

import {OnitSmartWallet, OnitSmartWalletFactory} from "../../lib/onit-smart-wallet/src/OnitSmartWalletFactory.sol";

contract OnitDeployer is Script {
    // address constant EXPECTED_IMPLEMENTATION = 0x000100abaad02f1cfC8Bbe32bD5a564817339E72;
    // address constant EXPECTED_FACTORY = 0x0BA5ED0c6AA8c49038F819E587E2633c4A9F428a;

    function run() public {
        console2.log("Deploying on chain ID", block.chainid);

        address implementation = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(OnitSmartWallet).creationCode,
            salt: keccak256("OnitSmartWallet")
        });
        console2.log("implementation", implementation);
        //assert(implementation == EXPECTED_IMPLEMENTATION);

        address factory = SafeSingletonDeployer.broadcastDeploy({
            creationCode: type(OnitSmartWalletFactory).creationCode,
            args: abi.encode(implementation),
            salt: keccak256("OnitSmartWalletFactory")
        });
        console2.log("factory", factory);
        //  assert(factory == EXPECTED_FACTORY);
    }
}
