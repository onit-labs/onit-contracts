// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC4337Account} from '../../src/erc4337-account/ERC4337Account.sol';
import {ERC4337AccountFactory} from '../../src/erc4337-account/ERC4337AccountFactory.sol';

import {DeploymentSelector} from '../../lib/foundry-deployment-manager/src/DeploymentSelector.sol';

/**
 * @dev This contract is used to deploy the ERC4337Factory contract
 * For now this must be run after the ERC4337AccountDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract ERC4337FactoryDeployer is DeploymentSelector {
	ERC4337Account internal account;

	address internal erc4337AccountSingleton;
	address internal entryPoint = 0x0576a174D229E3cFA37253523E645A78A0C91B57;
	address internal gnosisFallbackHandler = 0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4;

	function run() public {
		innerRun();
		outputDeployment();
	}

	function innerRun() public {
		startBroadcast();

		erc4337AccountSingleton = fork.get('ERC4337Account');

		bytes memory initData = abi.encode(
			erc4337AccountSingleton,
			entryPoint,
			gnosisFallbackHandler
		);

		(address contractAddress, bytes memory deploymentBytecode) = SelectDeployment(
			'ERC4337AccountFactory',
			initData
		);

		fork.set('ERC4337AccountFactory', contractAddress, deploymentBytecode);

		stopBroadcast();
	}
}
