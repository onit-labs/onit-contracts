// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable no-console */

import './config/ERC4337TestConfig.t.sol';
import {SignatureHelper} from './config/SignatureHelper.t.sol';

import {Base64} from '@libraries/Base64.sol';

/**
 * TODO
 * - Improve salt for group deployment. Should be more restrictive to prevent frontrunning, and should work cross chain
 */
contract Module4337Test is ERC4337TestConfig, SignatureHelper {
	ForumGroup private forumSafeModule;
	GnosisSafe private safe;

	// Some public keys used as signers in tests
	uint256[2] internal publicKey;
	uint256[2] internal publicKey2;
	uint256[] internal membersX;
	uint256[] internal membersY;

	string internal constant SIGNER_1 = '1';
	string internal constant SIGNER_2 = '2';

	string internal constant GROUP_NAME_1 = 'test';
	string internal constant GROUP_NAME_2 = 'test2';

	bytes internal basicTransferCalldata;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Create passkey signers
		publicKey = createPublicKey(SIGNER_1);
		publicKey2 = createPublicKey(SIGNER_2);

		// Format signers into arrays to be added to contract
		membersX.push(publicKey[0]);
		membersY.push(publicKey[1]);

		(
			// Deploy a forum safe from the factory
			forumSafeModule
		) = ForumGroup(
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_1, 5000, membersX, membersY))
		);

		// Deal the account some funds
		vm.deal(address(forumSafeModule), 1 ether);

		// Build a basic transaction to execute in some tests
		basicTransferCalldata = buildExecutionPayload(
			alice,
			uint256(0.5 ether),
			new bytes(0),
			Enum.Operation.Call
		);
	}

	/// -----------------------------------------------------------------------
	/// SETUP TESTS
	/// -----------------------------------------------------------------------

	function testSetupGroup() public {
		// Check the members and threshold are set
		uint256[2][] memory members = forumSafeModule.getMembers();

		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(forumSafeModule.voteThreshold() == 5000);
		assertTrue(forumSafeModule.entryPoint() == address(entryPoint));

		// The safe has been initialized with a threshold of 1
		// This threshold is not used when executing via entrypoint
		assertTrue(forumSafeModule.getThreshold() == 1);
	}

	function testDeployViaEntryPoint() public {
		// Encode the calldata for the factory to create an account
		bytes memory factoryCalldata = abi.encodeCall(
			forumGroupFactory.deployForumGroup,
			(GROUP_NAME_2, 5000, membersX, membersY)
		);

		//Prepend the address of the factory
		bytes memory initCode = abi.encodePacked(address(forumGroupFactory), factoryCalldata);

		// Calculate address in advance to use as sender
		address preCalculatedAccountAddress = forumGroupFactory.getAddress(
			keccak256(abi.encode(GROUP_NAME_2))
		);

		// Deal funds to account
		deal(preCalculatedAccountAddress, 1 ether);
		// Cast to ERC4337Account - used to make some test assertions easier
		ForumGroup newForumGroup = ForumGroup(payable(preCalculatedAccountAddress));

		// Build user operation
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = buildUserOp(preCalculatedAccountAddress, 0, initCode, basicTransferCalldata);

		// Get signature for userOp
		uint256[2][] memory sigs = new uint256[2][](2);
		sigs[0] = signMessageForPublicKey(
			SIGNER_1,
			Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(userOps[0])))
		);
		userOps[0].signature = abi.encode(sigs, authentacatorData);

		// Handle userOp
		entryPoint.handleOps(userOps, payable(alice));

		// Check the account has been deployed
		// check the members and threshold are set
		uint256[2][] memory members = newForumGroup.getMembers();

		assertTrue(members[0][0] == publicKey[0]);
		assertTrue(members[0][1] == publicKey[1]);
		assertTrue(newForumGroup.voteThreshold() == 5000);
		assertTrue(newForumGroup.entryPoint() == address(entryPoint));

		// The safe has been initialized with a threshold of 1
		// This threshold is not used when executing via entrypoint
		assertTrue(newForumGroup.getThreshold() == 1);
	}

	/// -----------------------------------------------------------------------
	/// FUNCTION TESTS
	/// -----------------------------------------------------------------------

	function testGetAddress() public {
		// Get address should predict correct deployed address
		assertTrue(
			forumGroupFactory.getAddress(keccak256(abi.encode(GROUP_NAME_1))) == address(safe)
		);
	}

	function testReturnAddressIfAlreadyDeployed() public {
		// Deploy a second forum safe with the same name
		ForumGroup newForumGroup = ForumGroup(
			payable(forumGroupFactory.deployForumGroup(GROUP_NAME_1, 5000, membersX, membersY))
		);

		// Get address should return the address of the first safe
		assertTrue(address(newForumGroup) == address(forumSafeModule));
	}

	function testUpdateThreshold(uint256 threshold) public {
		assertTrue(forumSafeModule.voteThreshold() == 5000);

		vm.startPrank(entryPointAddress);

		if (threshold < 1 || threshold > 10000) {
			vm.expectRevert(ForumGroup.InvalidThreshold.selector);
			forumSafeModule.setThreshold(threshold);
			threshold = 5000; // fallback to default so final assertiion is correctly evaluated
		} else {
			forumSafeModule.setThreshold(threshold);
		}

		assertTrue(forumSafeModule.voteThreshold() == threshold);
	}

	function testAddMember() public {
		assertTrue(forumSafeModule.getMembers().length == 1);

		vm.prank(entryPointAddress);
		forumSafeModule.addMember(publicKey2[0], publicKey2[1]);

		uint256[2][] memory members = forumSafeModule.getMembers();

		assertTrue(members[1][0] == publicKey2[0]);
		assertTrue(members[1][1] == publicKey2[1]);
		assertTrue(forumSafeModule.getMembers().length == 2);
	}

	/// -----------------------------------------------------------------------
	/// EXECUTION TESTS
	/// -----------------------------------------------------------------------

	// function testExecutionViaEntryPoint() public {
	// 	// check balance before
	// 	assertTrue(address(alice).balance == 1 ether);
	// 	assertTrue(address(safe).balance == 1 ether);
	// 	// assertTrue(forumSafeModule.nonce() == 0);

	// 	// Build user operation
	// 	UserOperation memory tmp = buildUserOp(
	// 		address(safe),
	// 		safe.nonce(),
	// 		new bytes(0),
	// 		basicTransferCalldata
	// 	);

	// 	// Get signatures for the user operation
	// 	uint256[2] memory s1 = signMessageForPublicKey(
	// 		SIGNER_1,
	// 		Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(tmp)))
	// 	);

	// 	// @dev signatures must be in the order members are added to the group (can be retrieved using getMembers())
	// 	uint256[2][] memory sigs = new uint256[2][](1);
	// 	sigs[0] = s1;

	// 	tmp.signature = abi.encode(sigs, authentacatorData);

	// 	UserOperation[] memory tmp1 = new UserOperation[](1);
	// 	tmp1[0] = tmp;

	// 	entryPoint.handleOps(tmp1, payable(alice));

	// 	// ! correct gas cost - take it from the useroperation event
	// 	uint256 gas = calculateGas(tmp);
	// 	// Transfer has been made, nonce incremented, used nonce set
	// 	assertTrue(address(alice).balance == 1.5 ether + gas);
	// 	assertTrue(address(safe).balance == 0.5 ether - gas);
	// 	assertTrue(safe.nonce() == 1);
	// 	//assertTrue(forumSafeModule.usedNonces(entryPoint.getUserOpHash(tmp)) == 1);
	// }

	// function testVotingWithEmptySig() public {
	// 	// Add second member to make  agroup of 2
	// 	membersX.push(publicKey2[0]);
	// 	membersY.push(publicKey2[1]);

	// 	(
	// 		// Deploy a forum safe from the factory with 2 signers
	// 		forumSafeModule,
	// 		safe
	// 	) = forumGroupFactory.deployForumGroup('test2', 5000, membersX, membersY);

	// 	deal(address(forumSafeModule), 10 ether);

	// 	// Build user operation
	// 	UserOperation memory tmp = buildUserOp(
	// 		address(safe),
	// 		safe.nonce(),
	// 		new bytes(0),
	// 		basicTransferCalldata
	// 	);

	// 	// Get signatures for the user operation
	// 	uint256[2] memory s1 = signMessageForPublicKey(
	// 		SIGNER_1,
	// 		Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(tmp)))
	// 	);
	// 	uint256[2] memory s2 = [uint256(0), uint256(0)];

	// 	uint256[2][] memory sigs = new uint256[2][](2);
	// 	sigs[0] = s1;
	// 	sigs[1] = s2;

	// 	tmp.signature = abi.encode(sigs, authentacatorData);

	// 	UserOperation[] memory tmp1 = new UserOperation[](1);
	// 	tmp1[0] = tmp;

	// 	entryPoint.handleOps(tmp1, payable(address(this)));

	// 	uint256 gas = calculateGas(tmp);

	// 	// Transfer has been made, nonce incremented, used nonce set
	// 	assertTrue(address(alice).balance == 1.5 ether);
	// 	assertTrue(address(safe).balance == 0.5 ether);
	// 	assertTrue(safe.nonce() == 1);
	// }

	// // test fail for below threshold
	// function testRevertsIfUnderThreshold() public {
	// 	// check balance before
	// 	assertTrue(address(alice).balance == 1 ether);
	// 	assertTrue(address(safe).balance == 1 ether);
	// 	assertTrue(safe.nonce() == 0);

	// 	//Add second member to make  agroup of 2
	// 	membersX.push(publicKey2[0]);
	// 	membersY.push(publicKey2[1]);

	// 	(
	// 		// Deploy a forum safe from the factory with 2 signers, over 50% threshold
	// 		forumSafeModule,
	// 		safe
	// 	) = forumGroupFactory.deployForumGroup('test2', 5001, membersX, membersY);

	// 	deal(address(forumSafeModule), 10 ether);

	// 	// Build user operation
	// 	UserOperation memory tmp = buildUserOp(
	// 		address(forumSafeModule),
	// 		safe.nonce(),
	// 		new bytes(0),
	// 		basicTransferCalldata
	// 	);

	// 	// Get signatures for the user operation
	// 	uint256[2] memory s1 = signMessageForPublicKey(
	// 		SIGNER_1,
	// 		Base64.encode(abi.encodePacked(entryPoint.getUserOpHash(tmp)))
	// 	);
	// 	// Empty as member 2 did not vote
	// 	uint256[2] memory s2 = [uint256(0), uint256(0)];

	// 	uint256[2][] memory sigs = new uint256[2][](2);
	// 	sigs[0] = s1;
	// 	sigs[1] = s2;

	// 	tmp.signature = abi.encode(sigs, authentacatorData);

	// 	UserOperation[] memory tmp1 = new UserOperation[](1);
	// 	tmp1[0] = tmp;

	// 	// Revert as not enough votes
	// 	vm.expectRevert(bytes('FailedOp(0, AA24 signature error)'));
	// 	entryPoint.handleOps(tmp1, payable(address(this)));

	// 	// Transfer has not been made, balances and nonce unchanged
	// 	assertTrue(address(alice).balance == 1 ether);
	// 	assertTrue(address(safe).balance == 1 ether);
	// 	assertTrue(safe.nonce() == 0);
	// }

	// prevent sig reuse

	receive() external payable {}

	/// -----------------------------------------------------------------------
	/// SETUP TESTS
	/// -----------------------------------------------------------------------

	// function getFallbackHandlerAndModule(
	// 	GnosisSafe _safe
	// ) internal view returns (ERC4337Fallback _fallback, ForumGroup _module) {
	// 	_fallback = ERC4337Fallback(
	// 		abi.decode(
	// 			_safe.getStorageAt(
	// 				0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5,
	// 				1
	// 			),
	// 			(address)
	// 		)
	// 	);

	// 	_module = ForumGroup(_fallback.erc4337module());
	// }
}
