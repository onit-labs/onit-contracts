// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC4337Account} from '../../src/erc4337-account/ERC4337Account.sol';
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';
import {DeploymentSelector} from '../../lib/foundry-deployment-manager/src/DeploymentSelector.sol';

/**
 * @dev This contract is used to deploy the ERC4337Account contract
 * For now this must be run before the ERC4337FactoryDeployer
 * Improvements to the deployment manager will allow this to be run in any order
 */
contract ERC4337AccountDeployer is DeploymentSelector {
	ERC4337Account internal account;

	address internal validator = 0xBa81560Ae6Bd24D34BB24084993AfdaFad3cfeff;

	function run() public {
		innerRun();
		outputDeployment();
	}

	function innerRun() public {
		startBroadcast();

		bytes memory initData = abi.encode(validator);

		(address contractAddress, bytes memory deploymentBytecode) = SelectDeployment(
			'ERC4337Account',
			initData
		);

		fork.set('ERC4337Account', contractAddress, deploymentBytecode);

		stopBroadcast();
	}
}
