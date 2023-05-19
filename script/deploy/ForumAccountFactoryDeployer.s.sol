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
    // New singleton deployed in previous script
    address internal forumAccountSingleton;

    // ! ENSURE THIS IS THE CORRECT ADDRESS FOR LATEST VERSION
    address internal entryPoint = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789; // v6 entry point

    address internal gnosisFallbackHandler = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4;

    function run() public {
        innerRun(); //outputDeployment();
    }

    function innerRun() public {
        startBroadcast();

        // ! ENSURE UPDATED VERSION IS SET ON CONTRACT
        forumAccountSingleton = fork.get("ForumAccount");

        address contractAddress;
        bytes memory deploymentBytecode;
        bytes memory initData;

        if (block.chainid == 137) {
            // First deploy staging
            initData = abi.encode(
                forumAccountSingleton,
                entryPoint,
                gnosisFallbackHandler,
                hex"03b6d35a71a78c74371a51a07459cb30b03a4cbea9885c8b656dd84e4175bce11d00000000",
                '{"type":"webauthn.get","challenge":"',
                '","origin":"https://staging.forumdaos.com"}'
            );
            (contractAddress, deploymentBytecode) = SelectDeployment("ForumAccountFactory", initData);

            // Then deploy production
            initData = abi.encode(
                forumAccountSingleton,
                entryPoint,
                gnosisFallbackHandler,
                hex"15fb388e36f88f11a3606dc4effb11f6a645d5c315366bdc62002118c776cea41d00000000",
                '{"type":"webauthn.get","challenge":"',
                '","origin":"https://forumdaos.com"}'
            );

            // Overwrite the staging address as we will take it from console for now, prod is more important to write
            (contractAddress, deploymentBytecode) = SelectDeployment("ForumAccountFactory", initData);
        } else {
            // Deploy development
            initData = abi.encode(
                forumAccountSingleton,
                entryPoint,
                gnosisFallbackHandler,
                hex"1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000",
                '{"type":"webauthn.get","challenge":"',
                '","origin":"https://development.forumdaos.com"}'
            );

            (contractAddress, deploymentBytecode) = SelectDeployment("ForumAccountFactory", initData);
        }

        fork.set("ForumAccountFactory", contractAddress, deploymentBytecode);

        stopBroadcast();
    }
}
