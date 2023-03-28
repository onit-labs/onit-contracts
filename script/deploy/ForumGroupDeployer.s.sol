// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from '../../src/erc4337-group/ForumGroup.sol';
import {DeploymentSelector} from '../../lib/foundry-deployment-manager/src/DeploymentSelector.sol';

/**
 * @dev This contract is used to deploy the ForumGroup contract
 * For now this must be run before the ForumGroupFactoryDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract ForumGroupDeployer is DeploymentSelector {
	address internal forumAccountSingleton;
	ForumGroup internal forumGroup;

	function run() public {
		innerRun();
		outputDeployment();
	}

	function innerRun() public {
		startBroadcast();

		forumAccountSingleton = fork.get('ForumAccount');

		// No longer using external validator
		bytes memory initData = abi.encode(forumAccountSingleton);

		(address contractAddress, bytes memory deploymentBytecode) = SelectDeployment(
			'ForumGroup',
			initData
		);

		fork.set('ForumGroup', contractAddress, deploymentBytecode);

		stopBroadcast();
	}
}
