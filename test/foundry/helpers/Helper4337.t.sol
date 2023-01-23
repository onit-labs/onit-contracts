// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {EntryPoint} from '@account-abstraction/core/EntryPoint.sol';
import {BaseAccount, UserOperation} from '@account-abstraction/core/BaseAccount.sol';

import {ForumSafeModule} from '../../../src/gnosis-forum/ForumSafeModule.sol';

import 'forge-std/Test.sol';

contract Helper4337 is Test {
	EntryPoint public entryPoint;

	address public entryPointAddress;

	constructor() {
		entryPoint = new EntryPoint();
		entryPointAddress = address(entryPoint);
	}

	// -----------------------------------------------------------------------
	// User Op Templates
	// -----------------------------------------------------------------------

	// Base for a  User Operation
	UserOperation public userOpBase =
		UserOperation({
			sender: address(0),
			nonce: 0,
			initCode: new bytes(0),
			callData: new bytes(0),
			callGasLimit: 0,
			verificationGasLimit: 1000000,
			preVerificationGas: 2100000,
			maxFeePerGas: 0,
			maxPriorityFeePerGas: 1e9,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});

	// -----------------------------------------------------------------------
	// 4337 Helper Functions
	// -----------------------------------------------------------------------

	function getNonce(BaseAccount account) internal view returns (uint256) {
		return account.nonce();
	}

	function buildUserOp(
		ForumSafeModule forumSafeModule,
		bytes memory callData,
		uint256 signerPk
	) public returns (UserOperation memory userOp) {
		// Build on top of base op
		userOp = userOpBase;

		// Add sender and calldata to op
		userOp.sender = address(forumSafeModule);
		userOp.callData = callData;

		// Get sig and add to op (sign the hast of the userop)
		bytes32 userOpHash = entryPoint.getUserOpHash(userOp);
		(uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, userOpHash);
		userOp.signature = abi.encodePacked(r, s, v);
	}
}
