// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {EIP4337Account} from '../../src/eip4337-account/EIP4337Account.sol';
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';
import {Deployer} from '../../lib/foundry-deployment-manager/src/Deployer.sol';

// TODO add check to avoid deploying if no change to bytecode
// TODO implement create2 proxy deployment

contract EIP4337AccountDeployer is Deployer {
	EIP4337Account public account;

	function run() public {
		innerRun();
		outputDeployment();
	}

	function innerRun() public {
		broadcast();

		account = new EIP4337Account(IEllipticCurveValidator(address(1)));

		fork.set('EIP4337Account', address(account));
	}
}
