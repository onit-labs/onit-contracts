// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumAccount} from "../../src/erc4337-account/ForumAccount.sol";
import {ForumAccountFactory} from "../../src/erc4337-account/ForumAccountFactory.sol";

import {DeploymentSelector} from "../../lib/foundry-deployment-manager/src/DeploymentSelector.sol";

/**
 * @dev This contract is used to deploy the ForumAccountFactory contract
 * For now this must be run after the ForumAccountDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract ForumAccountFactoryDeployer is DeploymentSelector {
    address internal forumAccountSingleton;
    address internal entryPoint = 0x0576a174D229E3cFA37253523E645A78A0C91B57;
    address internal gnosisFallbackHandler = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4;

    function run() public {
        innerRun();
        outputDeployment();
    }

    function innerRun() public {
        startBroadcast();

        forumAccountSingleton = fork.get("ForumAccount");

        bytes memory initData = abi.encode(forumAccountSingleton, entryPoint, gnosisFallbackHandler);

        (address contractAddress, bytes memory deploymentBytecode) = SelectDeployment("ForumAccountFactory", initData);

        fork.set("ForumAccountFactory", contractAddress, deploymentBytecode);

        stopBroadcast();
    }
}
