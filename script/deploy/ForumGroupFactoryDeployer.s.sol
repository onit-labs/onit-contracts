// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from '../../src/erc4337-group/ForumGroup.sol';
import {DeploymentSelector} from '../../lib/foundry-deployment-manager/src/DeploymentSelector.sol';

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

		forumGroupSingleton = fork.get('ForumGroup');

		bytes memory initData = abi.encode(
			forumGroupSingleton,
			entryPoint,
			gnosisSingleton,
			gnosisFallbackHandler
		);

		(address contractAddress, bytes memory deploymentBytecode) = SelectDeployment(
			'ForumGroupFactory',
			initData
		);

		fork.set('ForumGroupFactory', contractAddress, deploymentBytecode);

		stopBroadcast();
	}
}
