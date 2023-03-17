// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from '../../src/erc4337-group/ForumGroup.sol';
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';
import {DeploymentSelector} from '../../lib/foundry-deployment-manager/src/DeploymentSelector.sol';

/**
 * @dev This contract is used to deploy the ForumGroup contract
 * For now this must be run before the ForumGroupFactoryDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract ForumGroupDeployer is DeploymentSelector {
	ForumGroup internal forumGroup;

	address internal validator = 0xBa81560Ae6Bd24D34BB24084993AfdaFad3cfeff;

	function run() public {
		innerRun();
		outputDeployment();
	}

	function innerRun() public {
		startBroadcast();

		bytes memory initData = abi.encode(validator);

		(address contractAddress, bytes memory deploymentBytecode) = SelectDeployment(
			'ForumGroup',
			initData
		);

		fork.set('ForumGroup', contractAddress, deploymentBytecode);

		stopBroadcast();
	}
}
