// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {EIP4337Account} from '../../src/eip4337-account/EIP4337Account.sol';
import {EIP4337AccountFactory} from '../../src/eip4337-account/EIP4337AccountFactory.sol';

import {DeploymentSelector} from '../../lib/foundry-deployment-manager/src/DeploymentSelector.sol';

/**
 * @dev This contract is used to deploy the EIP4337Factory contract
 * For now this must be run after the EIP4337AccountDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract EIP4337FactoryDeployer is DeploymentSelector {
	EIP4337Account internal account;

	address internal eip4337AccountSingleton;
	address internal entryPoint = 0x0576a174D229E3cFA37253523E645A78A0C91B57;
	address internal gnosisFallbackHandler = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4;

	function run() public {
		innerRun();
		outputDeployment();
	}

	function innerRun() public {
		startBroadcast();

		eip4337AccountSingleton = fork.get('EIP4337Account');

		bytes memory initData = abi.encode(
			eip4337AccountSingleton,
			entryPoint,
			gnosisFallbackHandler
		);

		(address contractAddress, bytes memory deploymentBytecode) = SelectDeployment(
			'EIP4337AccountFactory',
			initData
		);

		fork.set('EIP4337AccountFactory', contractAddress, deploymentBytecode);

		stopBroadcast();
	}
}
