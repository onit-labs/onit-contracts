// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// 4337 imports
import {EntryPoint} from '@erc4337/core/EntryPoint.sol';
import {BaseAccount, UserOperation} from '@erc4337/core/BaseAccount.sol';

// Forum 4337 contracts
import {ForumAccount} from '../../src/erc4337-account/ForumAccount.sol';
import {ForumAccountFactory} from '../../src/erc4337-account/ForumAccountFactory.sol';
import {ForumGroup} from '../../src/erc4337-group/ForumGroup.sol';
import {ForumGroupFactory} from '../../src/erc4337-group/ForumGroupFactory.sol';
import {MemberManager} from '@utils/MemberManager.sol';

// Lib for encoding
import {Base64} from '@libraries/Base64.sol';

import './SafeTestConfig.t.sol';
import './BasicTestConfig.t.sol';
import {SignatureHelper} from './SignatureHelper.t.sol';

contract ERC4337TestConfig is BasicTestConfig, SafeTestConfig, SignatureHelper {
	// Entry point
	EntryPoint public entryPoint;

	// Singleton for Forum 4337 account implementation
	ForumAccount public forumAccountSingleton;

	// Singleton for Forum 4337 group account implementation
	ForumGroup public forumGroupSingleton;

	// Factory for individual 4337 accounts
	ForumAccountFactory public forumAccountFactory;

	// Factory for 4337 group accounts
	ForumGroupFactory public forumGroupFactory;

	// Addresses for easy use in tests
	address internal entryPointAddress;

	string internal authentacatorData =
		'1584482fdf7a4d0b7eb9d45cf835288cb59e55b8249fff356e33be88ecc546d11d00000000';

	constructor() {
		entryPoint = new EntryPoint();
		entryPointAddress = address(entryPoint);

		forumAccountSingleton = new ForumAccount();
		forumGroupSingleton = new ForumGroup(address(forumAccountSingleton));

		forumAccountFactory = new ForumAccountFactory(
			forumAccountSingleton,
			entryPointAddress,
			address(handler)
		);

		forumGroupFactory = new ForumGroupFactory(
			payable(address(forumGroupSingleton)),
			entryPointAddress,
			address(safeSingleton),
			address(handler)
		);
	}

	// -----------------------------------------------------------------------
	// 4337 Helper Functions
	// -----------------------------------------------------------------------

	UserOperation public userOpBase =
		UserOperation({
			sender: address(0),
			nonce: 0,
			initCode: new bytes(0),
			callData: new bytes(0),
			callGasLimit: 10000000,
			verificationGasLimit: 20000000,
			preVerificationGas: 20000000,
			maxFeePerGas: 2,
			maxPriorityFeePerGas: 1,
			paymasterAndData: new bytes(0),
			signature: new bytes(0)
		});

	function getNonce(BaseAccount account) internal view returns (uint256) {
		return account.nonce();
	}

	function buildUserOp(
		address sender,
		uint256 nonce,
		bytes memory initCode,
		bytes memory callData
	) public view returns (UserOperation memory userOp) {
		// Build on top of base op
		userOp = userOpBase;

		// Add sender and calldata to op
		userOp.sender = sender;
		userOp.nonce = nonce;
		userOp.initCode = initCode;
		userOp.callData = callData;
	}

	// Build payload which the entryPoint will call on the sender 4337 account
	function buildExecutionPayload(
		address to,
		uint256 value,
		bytes memory data,
		Enum.Operation operation
	) internal pure returns (bytes memory) {
		return
			abi.encodeWithSignature(
				'executeAndRevert(address,uint256,bytes,uint8)',
				to,
				value,
				data,
				operation
			);
	}

	// !!!!! combine with the above
	function signAndFormatUserOpIndividual(
		UserOperation memory userOp,
		string memory signer1
	) internal returns (UserOperation[] memory) {
		userOp.signature = abi.encode(
			signMessageForPublicKey(
				signer1,
				Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp)))
			),
			'{"type":"webauthn.get","challenge":"',
			'","origin":"https://development.forumdaos.com"}',
			authentacatorData
		);

		UserOperation[] memory userOpArray = new UserOperation[](1);
		userOpArray[0] = userOp;

		return userOpArray;
	}

	// Gathers signatures from signers and formats them into the signature field for the user operation
	// Maybe only one sig is needed, so siger2 may be empty
	function signAndFormatUserOp(
		UserOperation memory userOp,
		string memory signer1,
		string memory signer2
	) internal returns (UserOperation[] memory) {
		uint256 signerCount;
		uint256[2] memory sig1;
		uint256[2] memory sig2;

		// Get signature for the user operation
		sig1 = signMessageForPublicKey(
			signer1,
			Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp)))
		);

		// If signer2 is not empty, get signature for it
		if (bytes(signer2).length > 0) {
			sig2 = signMessageForPublicKey(
				signer2,
				Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOp)))
			);
			signerCount = 2;
		} else {
			signerCount = 1;
		}

		// Build the signatures into an array
		uint256[2][] memory sigs = new uint256[2][](signerCount);
		sigs[0] = sig1;
		if (signerCount == 2) {
			sigs[1] = sig2;
		}

		/// @dev The signatures are added to the user op with some extra information
		// 1) The index of each signer in an array
		//		- for these tests we know that signer1 is at index 1 and signer2 is at index 0
		//		- this is because when accounts are added they are put to the front of the linked list
		//		- in production we can get this information by calling getMembers and getting the index of each signer
		// 2) The authentacator data

		// Build the array of signer indexes
		/// @dev We see that if there is only one signer, the index is 0
		// 		- this is because if there is only one signer, they are at index 0
		//		- if there are two signers, the first signer is at index 1 and the second is at index 0 because of how they are added to the linked list
		uint256[] memory signerIndexes = new uint256[](signerCount);
		if (signerCount == 1) {
			signerIndexes[0] = 0;
		} else {
			signerIndexes[0] = 1;
			signerIndexes[1] = 0;
		}

		userOp.signature = abi.encode(
			signerIndexes,
			sigs,
			'{"type":"webauthn.get","challenge":"',
			'","origin":"https://development.forumdaos.com"}',
			authentacatorData
		);

		UserOperation[] memory userOpArray = new UserOperation[](1);
		userOpArray[0] = userOp;

		return userOpArray;
	}

	// Calculate gas used by sender of userOp
	// ! currently only works when paymaster set to 0 - hence 'address(0) != address(0)'
	function calculateGas(UserOperation memory userOp) internal pure returns (uint256) {
		uint256 mul = address(0) != address(0) ? 3 : 1;
		uint256 requiredGas = userOp.callGasLimit +
			userOp.verificationGasLimit *
			mul +
			userOp.preVerificationGas;

		return requiredGas * userOp.maxFeePerGas;
	}

	function failedOpError(
		uint256 opIndex,
		string memory reason
	) internal pure returns (bytes memory) {
		return abi.encodeWithSignature('FailedOp(uint256,string)', opIndex, reason);
	}
}
