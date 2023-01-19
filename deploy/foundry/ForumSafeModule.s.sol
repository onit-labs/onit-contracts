// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import '../../src/gnosis-forum/ForumSafeModule.sol';

contract DeployForumSafeModule is Script {
	function run() external {
		uint256 deployerKey = vm.envUint('FUJI_PRIVATE_KEY');
		address deployerAddress = vm.addr(deployerKey);

		vm.startBroadcast(deployerKey);

		ForumSafeModule forumSafeModule = new ForumSafeModule(deployerAddress);

		vm.stopBroadcast();
	}
}
