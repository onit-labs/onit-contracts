// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/* solhint-disable no-console */

import './config/BasicTestConfig.t.sol';

import 'forge-std/console.sol';

contract Demo {}

contract TestString is BasicTestConfig {
	string internal clientDataStart = '{"type":"webauthn.get","challenge":"';
	string internal clientDataEndDevelopment = '","origin":"https://development.forumdaos.com"}';

	// test string is below 32 bytes
	function testSizeOfStrings() public {
		console.log(bytes(clientDataStart).length);
		console.log(bytes(clientDataEndDevelopment).length);

		// console.log(bytes(1).length);
		console.log(bytes('1').length);
	}

	function testAssignInLine() public {
		uint t1 = 1;
		uint t2 = 2;
		uint r1 = 3;

		(t1, t2, r1) = (t1 + t2, t1 + r1, r1 + 10);

		console.log(t1);
		console.log(t2);
		console.log(r1);
	}

	// test cost of riting immutable

	// test cost of reading a string from storage

	// test cost of packing and unpacking a string to bytes
}
