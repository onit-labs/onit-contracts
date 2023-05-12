// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from "../../src/erc4337-group/ForumGroup.sol";
import {DeploymentSelector} from "../../lib/foundry-deployment-manager/src/DeploymentSelector.sol";

/**
 * @dev This contract is used to deploy the ForumGroupFactory contract
 * For now this must be run after the ForumGroupDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract ForumGroupFactoryDeployer is DeploymentSelector {
    address internal forumGroupSingleton;
    address internal entryPoint = 0x0576a174D229E3cFA37253523E645A78A0C91B57;
    address internal gnosisSingleton = 0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552;
    address internal gnosisFallbackHandler = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4;

    function run() public {
        innerRun();
        outputDeployment();
    }

    function innerRun() public {
        startBroadcast();

        forumGroupSingleton = fork.get("ForumGroup");

        address contractAddress;
        bytes memory deploymentBytecode;
        bytes memory initData;

        if (block.chainid == 137) {
            // First deploy staging
            initData = abi.encode(
                forumGroupSingleton,
                entryPoint,
                gnosisFallbackHandler,
                hex"03b6d35a71a78c74371a51a07459cb30b03a4cbea9885c8b656dd84e4175bce11d00000000",
                '{"type":"webauthn.get","challenge":"',
                '","origin":"https://staging.forumdaos.com"}'
            );
            (contractAddress, deploymentBytecode) = SelectDeployment("ForumGroupFactory", initData);

            // Then deploy production
            initData = abi.encode(
                forumGroupSingleton,
                entryPoint,
                gnosisFallbackHandler,
                hex"15fb388e36f88f11a3606dc4effb11f6a645d5c315366bdc62002118c776cea41d00000000",
                '{"type":"webauthn.get","challenge":"',
                '","origin":"https://forumdaos.com"}'
            );

            // Overwrite the staging address as we will take it from console for now, prod is more important to write
            (contractAddress, deploymentBytecode) = SelectDeployment("ForumGroupFactory", initData);
        } else {
            // Deploy development
            initData = abi.encode(
                forumGroupSingleton,
                entryPoint,
                gnosisFallbackHandler,
                hex"1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000",
                '{"type":"webauthn.get","challenge":"',
                '","origin":"https://development.forumdaos.com"}'
            );

            (contractAddress, deploymentBytecode) = SelectDeployment("ForumGroupFactory", initData);
        }

        initData = abi.encode(forumGroupSingleton, entryPoint, gnosisSingleton, gnosisFallbackHandler);

        fork.set("ForumGroupFactory", contractAddress, deploymentBytecode);

        stopBroadcast();
    }
}
