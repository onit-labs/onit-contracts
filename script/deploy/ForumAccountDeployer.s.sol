// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumAccount} from "../../src/erc4337-account/ForumAccount.sol";
import {DeploymentSelector} from "../../lib/foundry-deployment-manager/src/DeploymentSelector.sol";

/**
 * @dev This contract is used to deploy the ForumAccount contract
 * For now this must be run before the ERC4337FactoryDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract ForumAccountDeployer is DeploymentSelector {
    ForumAccount internal account;

    function run() public {
        innerRun();
        outputDeployment();
    }

    function innerRun() public {
        startBroadcast();

        // No longer using external validator
        bytes memory initData = new bytes(0);

        (address contractAddress, bytes memory deploymentBytecode) = SelectDeployment("ForumAccount", initData);

        fork.set("ForumAccount", contractAddress, deploymentBytecode);

        stopBroadcast();
    }
}
