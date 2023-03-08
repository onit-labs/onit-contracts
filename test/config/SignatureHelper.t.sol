// SPDX-License-Identifier UNLICENSED
pragma solidity ^0.8.13;

/* solhint-disable no-console */

import './BasicTestConfig.t.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

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

		uint256[2] memory s = abi.decode(res, (uint256[2]));

		console.log(s[0]);
		console.log(s[1]);

		return s;
	}

	function signMessageForPublicKey(
		bytes32 message,
		uint256[2] memory publicKey
	) public returns (uint256[2] memory) {
		string[] memory cmd = new string[](8);

		cmd[0] = 'yarn';
		cmd[1] = '--silent';
		cmd[2] = 'ts-node';
		cmd[3] = 'script/signatureHelper.ts';
		cmd[4] = 'sign';
		cmd[5] = bytes32ToString(message);
		cmd[6] = Strings.toString(publicKey[0]);
		cmd[7] = Strings.toString(publicKey[1]);

		bytes memory res = vm.ffi(cmd);

		//bytes memory sig = vm.ffi(cmd);
		uint256[2] memory sig = abi.decode(res, (uint256[2]));

		console.log(sig[0]);
		console.log(sig[1]);

		return sig;
	}

	function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
		uint8 i = 0;
		while (i < 32 && _bytes32[i] != 0) {
			i++;
		}
		bytes memory bytesArray = new bytes(i);
		for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
			bytesArray[i] = _bytes32[i];
		}
		return string(bytesArray);
	}
}
