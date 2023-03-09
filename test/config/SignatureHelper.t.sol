// SPDX-License-Identifier UNLICENSED
pragma solidity ^0.8.13;

/* solhint-disable no-console */

import {BasicTestConfig} from './BasicTestConfig.t.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

/**
 * @notice - This contract runs the signatureHelper.ts script
 * 			 It is used to create and sign messages, similar to how the passkey would, for testing
 */
contract SignatureHelper is BasicTestConfig {
	function createPublicKey(string memory salt) public returns (uint256[2] memory) {
		string[] memory cmd = new string[](6);

		cmd[0] = 'yarn';
		cmd[1] = '--silent';
		cmd[2] = 'ts-node';
		cmd[3] = 'script/signatureHelper.ts';
		cmd[4] = 'gen';
		cmd[5] = salt;

		bytes memory res = vm.ffi(cmd);

		uint256[2] memory publicKey = abi.decode(res, (uint256[2]));

		// console.log('keys');
		// console.log(publicKey[0]);
		// console.log(s[1]);

		return publicKey;
	}

	function signMessageForPublicKey(
		string memory salt,
		string memory message
	) public returns (uint256[2] memory) {
		string[] memory cmd = new string[](7);

		cmd[0] = 'yarn';
		cmd[1] = '--silent';
		cmd[2] = 'ts-node';
		cmd[3] = 'script/signatureHelper.ts';
		cmd[4] = 'sign';
		cmd[5] = salt;
		cmd[6] = message;

		bytes memory res = vm.ffi(cmd);

		//console.log(string(res));

		uint256[2] memory sig = abi.decode(res, (uint256[2]));

		// console.log('sigs');
		// console.log(sig[0]);
		// console.log(sig[1]);

		return sig;
	}
}
