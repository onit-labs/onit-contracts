// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';

import '../../src/eip4337-account/EIP4337Account.sol';
import {EntryPoint} from '@eip4337/contracts/core/EntryPoint.sol';
import {EIP4337AccountFactory} from '../../src/eip4337-account/EIP4337AccountFactory.sol';
import {EllipticCurve} from '@utils/EllipticCurve.sol';
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';

contract DeployEip4337Account is Script {
	function run() external {
		uint256 deployerKey = vm.envUint('MUMBAI_PRIVATE_KEY');
		address deployerAddress = vm.addr(deployerKey);

		vm.startBroadcast(deployerKey);

		EllipticCurve ellipticCurve = new EllipticCurve();

		EIP4337Account eip4337Account = new EIP4337Account(
			IEllipticCurveValidator(address(ellipticCurve))
		);
		EntryPoint entryPoint = new EntryPoint();

		EIP4337AccountFactory factory = new EIP4337AccountFactory(
			(eip4337Account),
			(entryPoint),
			address(0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4)
		);

		vm.stopBroadcast();
	}
}
