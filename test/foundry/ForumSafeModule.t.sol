// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import './helpers/ForumSafeTestConfig.t.sol';
import './helpers/TokenTestConfig.t.sol';

import 'forge-std/console.sol';

// ! Consider
// Other interactions which can happen between module and safe?

contract ForumSafeModuleTest is ForumSafeTestConfig, TokenTestConfig {
	ForumSafeModule private forumSafeModule;
	GnosisSafe private safe;

	address private safeAddress;
	address private moduleAddress;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Deploy a forum safe from the factory
		(forumSafeModule, safe) = forumSafeFactory.deployForumSafe(
			'test',
			'T',
			[uint32(60), uint32(12), uint32(50), uint32(80)],
			voters,
			initialExtensions
		);

		safeAddress = address(safe);
		moduleAddress = address(forumSafeModule);

		// Mint the safe some tokens
		mockErc20.mint(safeAddress, 1 ether);
		mockErc1155.mint(safeAddress, 0, 1, '');
		mockErc721.mint(safeAddress, 1);
	}

	/// -----------------------------------------------------------------------
	/// Admin operations on Safe and Module
	/// -----------------------------------------------------------------------

	function testModuleAddsOwnerToSafe() public {
		assertFalse(safe.isOwner(address(this)));

		// Create payload to add owner (any address will do) to safe
		bytes memory addOwnerPayload = abi.encodeWithSignature(
			'addOwnerWithThreshold(address,uint256)',
			address(this),
			1
		);

		// Multicall is delegate called by the safe
		// This lets it be used to call any function on any contract, where the call must come from owner
		// Consider additional input field in proposal to specify operation
		bytes memory multisendPayload = buildSafeMultisend(
			Operation.CALL,
			safeAddress,
			0,
			addOwnerPayload
		);

		// Create proposal to add owner to safe
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		processProposal(prop, forumSafeModule, true);

		// Check owner is added to safe
		assertTrue(safe.isOwner(address(this)));
	}

	function testUpdateOwnerOnModule() public {
		assertEq(forumSafeModule.owner(), safeAddress);

		// Create payload to update owner on module
		bytes memory changeOwnerPayload = abi.encodeWithSignature(
			'transferOwnership(address)',
			alice
		);

		bytes memory multisendPayload = buildSafeMultisend(
			Operation.CALL,
			moduleAddress,
			0,
			changeOwnerPayload
		);

		// Create proposal to update owner on module
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		processProposal(prop, forumSafeModule, true);

		// Check owner is updated on module
		assertEq(forumSafeModule.owner(), alice);
	}

	function testUpdateAvatarOnModule() public {
		assertEq(forumSafeModule.avatar(), safeAddress);

		// Create payload to update avatar on module
		bytes memory changeAvatarPayload = abi.encodeWithSignature('setAvatar(address)', alice);

		bytes memory multisendPayload = buildSafeMultisend(
			Operation.CALL,
			moduleAddress,
			0,
			changeAvatarPayload
		);

		// Create proposal to update avatar on module
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		processProposal(prop, forumSafeModule, true);

		// Check avatar is updated on module
		assertEq(forumSafeModule.avatar(), alice);
	}

	function testUpdateTargetOnModule() public {
		assertEq(forumSafeModule.target(), safeAddress);

		// Create payload to update target on module
		bytes memory changeTargetPayload = abi.encodeWithSignature('setTarget(address)', alice);

		bytes memory multisendPayload = buildSafeMultisend(
			Operation.CALL,
			moduleAddress,
			0,
			changeTargetPayload
		);

		// Create proposal to update target on module
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		processProposal(prop, forumSafeModule, true);

		// Check target is updated on module
		assertEq(forumSafeModule.target(), alice);
	}

	/// -----------------------------------------------------------------------
	/// Module execution on safe
	/// -----------------------------------------------------------------------

	// ! check flow of call here (module -> multisend -> safe.. but admin op should be self called by safe)
	function testModuleAddsOtherModuleToSafe() public {
		// Create payload to enable module (any address will do for example) on safe
		bytes memory enableModulePayload = abi.encodeWithSignature(
			'enableModule(address)',
			address(this)
		);

		bytes memory multisendPayload = buildSafeMultisend(
			Operation.CALL,
			safeAddress,
			0,
			enableModulePayload
		);

		// Create proposal to enable module on safe
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		processProposal(prop, forumSafeModule, true);

		// Check module is enabled on safe
		assertTrue(safe.isModuleEnabled(address(this)));
	}

	function testAddingMemberToModuleAddsToSafe() public {
		assertFalse(safe.isOwner(bob));

		// Create MINT proposal to forum module
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.MINT,
			[bob],
			[uint256(0)],
			[bytes('')]
		);

		processProposal(prop, forumSafeModule, true);

		// Check owner is added to safe
		assertTrue(safe.isOwner(bob));
	}

	function testRevertsIfExternalCallReverts() public {
		// Create failing payload for execution
		bytes memory wrongPayload = abi.encodeWithSignature('thisWillFail(address)', address(this));

		// Create proposal to enable module on safe
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[safeAddress],
			[uint256(0)],
			[wrongPayload]
		);

		// Process proposal
		processProposal(prop, forumSafeModule, false);

		// Check module is not enabled on safe
		assertTrue(!safe.isModuleEnabled(address(this)));
	}

	function testEnablesSafeToRescueTokensOnModule() public {
		// Mint tokens to module, and create Transfer payload
		mockErc20.mint(moduleAddress, 100);
		bytes memory transferPayload = abi.encodeWithSignature(
			'transfer(address,uint256)',
			alice,
			100
		);

		// ExecuteFromModule payload for module to call on safe
		bytes memory executeAsModulePayload = abi.encodeWithSignature(
			'executeAsModule(address,uint256,bytes)',
			address(mockErc20),
			uint256(0),
			transferPayload
		);

		// Propose transfer from module
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[moduleAddress],
			[uint256(0)],
			[executeAsModulePayload]
		);

		processProposal(prop, forumSafeModule, true);
	}

	// Prevents a user making calls from the module
	function testCannotExecuteExternally() public {
		// Transfer payload to attempt
		bytes memory transferPayload = abi.encodeWithSignature(
			'transfer(address,uint256)',
			alice,
			100
		);

		// ExecuteFromModule payload for module to call on safe
		bytes memory executeAsModulePayload = abi.encodeWithSignature(
			'execTransactionFromModule(address,uint256,bytes,uint8)',
			address(mockErc20),
			uint256(0),
			transferPayload,
			Operation.DELEGATECALL
		);

		vm.expectRevert(bytes4(keccak256('AvatarOnly()')));
		forumSafeModule.executeAsModule(safeAddress, uint256(0), executeAsModulePayload);

		vm.prank(safeAddress, safeAddress);
		forumSafeModule.executeAsModule(safeAddress, uint256(0), executeAsModulePayload);
	}

	function testAdds1271SigToSafe() public {}

	function testSingleProposalViaSafe() public {
		// Create transfer proposal
		bytes memory transferPayload = abi.encodeWithSignature(
			'transfer(address,uint256)',
			alice,
			0.5 ether
		);

		// Create proposal with transfer payload to erc20
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(mockErc20)],
			[uint256(0)],
			[transferPayload]
		);

		// Execute proposal
		processProposal(prop, forumSafeModule, true);

		// Check balance of alice and safe
		assertEq(mockErc20.balanceOf(alice), 0.5 ether);
		assertEq(mockErc20.balanceOf(safeAddress), 0.5 ether);
	}

	function testMultisendProposalViaSafe() public {
		// Create erc20 transfer proposal
		bytes memory transferPayload = abi.encodeWithSignature(
			'transfer(address,uint256)',
			alice,
			0.5 ether
		);

		// Create erc1155 transfer proposal
		bytes memory transfer1155Payload = abi.encodeWithSignature(
			'safeTransferFrom(address,address,uint256,uint256,bytes)',
			safeAddress,
			alice,
			0,
			1,
			''
		);

		// Create multisend payload
		bytes memory multisendPayload = abi.encodeWithSignature(
			'multiSend(bytes)',
			bytes.concat(
				abi.encodePacked(
					Operation.CALL,
					address(mockErc20),
					uint256(0),
					uint256(transferPayload.length),
					transferPayload
				),
				abi.encodePacked(
					Operation.CALL,
					address(mockErc1155),
					uint256(0),
					uint256(transfer1155Payload.length),
					transfer1155Payload
				)
			)
		);

		// Create proposal with multisend payload
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		// Execute proposal
		processProposal(prop, forumSafeModule, true);

		// Check balance of alice and safe
		assertEq(mockErc20.balanceOf(alice), 0.5 ether);
		assertEq(mockErc20.balanceOf(safeAddress), 0.5 ether);
		assertEq(mockErc1155.balanceOf(alice, 0), 1);
		assertEq(mockErc1155.balanceOf(safeAddress, 0), 0);
	}

	function testCannotExecMultisendIfPartFails() public {
		// Create erc20 transfer proposal to fail (not enough balance for 5 eth)
		bytes memory transferPayload = abi.encodeWithSignature(
			'transfer(address,uint256)',
			alice,
			5 ether
		);

		// Create erc1155 transfer proposal
		bytes memory transfer1155Payload = abi.encodeWithSignature(
			'safeTransferFrom(address,address,uint256,uint256,bytes)',
			safeAddress,
			alice,
			0,
			1,
			''
		);

		// Create multisend payload
		bytes memory multisendPayload = abi.encodeWithSignature(
			'multiSend(bytes)',
			bytes.concat(
				abi.encodePacked(
					Operation.CALL,
					address(mockErc20),
					uint256(0),
					uint256(transferPayload.length),
					transferPayload
				),
				abi.encodePacked(
					Operation.CALL,
					address(mockErc1155),
					uint256(0),
					uint256(transfer1155Payload.length),
					transfer1155Payload
				)
			)
		);

		// Create proposal with multisend payload
		uint256 prop = proposeToForum(
			forumSafeModule,
			IForumGroupTypes.ProposalType.CALL,
			[address(multisend)],
			[uint256(0)],
			[multisendPayload]
		);

		// Execute proposal, should revert
		processProposal(prop, forumSafeModule, false);

		// Check balance of alice and safe, should not change
		assertEq(mockErc20.balanceOf(alice), 0);
		assertEq(mockErc20.balanceOf(safeAddress), 1 ether);
		assertEq(mockErc1155.balanceOf(alice, 0), 0);
		assertEq(mockErc1155.balanceOf(safeAddress, 0), 1);
	}

	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------
}
