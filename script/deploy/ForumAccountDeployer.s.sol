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

    // TODO improve the linking of this lib
    address internal constant FCL_ELLIPTIC_ZZ = 0xbb93A0Ca0EDb4a726f37433993ED22376CD8387a;

    function run() public {
        innerRun();
        outputDeployment();
    }

    function innerRun() public {
        startBroadcast();

        // No longer using external validator
        bytes memory initData = abi.encode(FCL_ELLIPTIC_ZZ);

        // ! ENSURE UPDATED VERSION IS SET ON CONTRACT
        (address contractAddress, bytes memory deploymentBytecode) = SelectDeployment("ForumAccount", initData);

        fork.set("ForumAccount", contractAddress, deploymentBytecode);

        stopBroadcast();
    }
}
