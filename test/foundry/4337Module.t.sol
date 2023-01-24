// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// import './helpers/ForumSafeTestConfig.t.sol';
import './helpers/Helper4337.t.sol';

contract Module4337Test is Helper4337 {
	ForumSafe4337Module private forumSafeModule;
	GnosisSafe private safe;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Deploy a forum safe from the factory
		(forumSafeModule, safe) = forumSafe4337Factory.deployForumSafe(
			'test',
			'T',
			[uint32(60), uint32(12), uint32(50), uint32(80)],
			voters,
			initialExtensions
		);

		// Set addresses for easier use in tests
		moduleAddress = address(forumSafeModule);
		safeAddress = address(safe);

		vm.deal(safeAddress, 1 ether);
	}

	/// -----------------------------------------------------------------------
	/// Tests
	/// -----------------------------------------------------------------------

	function testProcessPropViaEntryPoint() public {
		console.log(entryPointAddress);

		// check alices balance before
		assertTrue(address(alice).balance == 1 ether);
		assertTrue(address(safe).balance == 1 ether);

		address[] memory accounts = new address[](1);
		uint256[] memory amounts = new uint256[](1);
		bytes[] memory payloads = new bytes[](1);
		accounts[0] = alice;
		amounts[0] = 0.5 ether;
		payloads[0] = new bytes(0);

		forumSafeModule.propose(
			IForumSafeModuleTypes.ProposalType.CALL,
			Enum.Operation.Call,
			accounts,
			amounts,
			payloads
		);

		IForumSafeModuleTypes.Signature[] memory ts = new IForumSafeModuleTypes.Signature[](1);
		ts[0] = IForumSafeModuleTypes.Signature({v: 28, r: keccak256('0x'), s: keccak256('0x')});

		bytes memory processPropCalldata = abi.encodeWithSignature(
			'processProposal(uint256,(uint8,bytes32,bytes32)[])',
			1,
			ts
		);

		// build user operation
		UserOperation memory tmp = buildUserOp(forumSafeModule, processPropCalldata, alicePk);

		UserOperation[] memory tmp1 = new UserOperation[](1);
		tmp1[0] = tmp;

		entryPoint.handleOps(tmp1, payable(alice));

		console.log(address(alice).balance);

		assertTrue(address(alice).balance == 1.5 ether);
	}
}
