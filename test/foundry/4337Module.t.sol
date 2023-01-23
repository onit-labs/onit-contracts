// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import './helpers/ForumSafeTestConfig.t.sol';
import './helpers/Helper4337.t.sol';

contract Module4337Test is ForumSafeTestConfig, Helper4337 {
	ForumSafeModule private forumSafeModule;
	GnosisSafe private safe;

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

		// Set addresses for easier use in tests
		moduleAddress = address(forumSafeModule);
		safeAddress = address(safe);

		vm.deal(moduleAddress, 1 ether);
	}

	/// -----------------------------------------------------------------------
	/// Tests
	/// -----------------------------------------------------------------------

	function testProcessPropViaEntryPoint() public {
		console.log(entryPointAddress);

		// Create a proposal to send alice 0.5 eth
		proposeToForum(
			forumSafeModule,
			IForumSafeModuleTypes.ProposalType.CALL,
			Enum.Operation.DelegateCall,
			[alice],
			[uint256(0.5 ether)],
			[new bytes(0)]
		);

		IForumSafeModuleTypes.Signature[] memory ts = new IForumSafeModuleTypes.Signature[](1);
		ts[0] = IForumSafeModuleTypes.Signature({v: 28, r: keccak256('0x'), s: keccak256('0x')});

		// bytes memory processPropCalldata = abi.encodePacked(
		// 	keccak256('processProposal(uint256,Signature[])'),
		// 	(abi.encode(0, ts))
		// );

		bytes memory processPropCalldata = abi.encodeWithSignature(
			'processProposal(uint256,Signature[])',
			1,
			ts
		);

		// build user operation
		UserOperation memory tmp = buildUserOp(forumSafeModule, processPropCalldata, alicePk);

		UserOperation[] memory tmp1 = new UserOperation[](1);
		tmp1[0] = tmp;

		entryPoint.handleOps(tmp1, payable(alice));
	}
}
