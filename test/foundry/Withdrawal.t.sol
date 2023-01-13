// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TestShareManager} from '../../src/test-contracts/TestShareManager.sol';
import {ForumWithdrawalExtension} from '../../src/gnosis-forum/extensions/withdrawal/ForumWithdrawalExtension.sol';
import {WithdrawalTransferManager} from '../../src/gnosis-forum/extensions/withdrawal/WithdrawalTransferManager.sol';

import './helpers/ForumSafeTestConfig.t.sol';

contract WithdrawalTest is ForumSafeTestConfig {
	ForumSafeModule internal forumModule;
	GnosisSafe internal safe;

	// Extension to handle withdrawal from safe based on ownership of treasury
	ForumWithdrawalExtension public forumWithdrawal;
	// Creates payloads for withdrawals
	WithdrawalTransferManager public withdrawalTransferManager;
	// Handles the distribution of group shares (makes testing easier than doing fundraises)
	TestShareManager public groupShareManager;

	// Another erc20 to test multiple withdrawals
	MockERC20 internal mockErc20_2;

	address internal moduleAddress;
	address internal safeAddress;
	address[] internal tokens;

	uint256 internal constant TOKEN = 0;

	uint256 internal WITHDRAWAL_START = block.timestamp;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		// Contracts used in withdrawal tests
		withdrawalTransferManager = new WithdrawalTransferManager();
		forumWithdrawal = new ForumWithdrawalExtension(address(withdrawalTransferManager));
		groupShareManager = new TestShareManager();

		//  Set the extensions
		(initialExtensions[0], initialExtensions[1]) = (
			address(groupShareManager),
			address(forumWithdrawal)
		);

		// Deploy a module and safe
		(forumModule, safe) = forumSafeFactory.deployForumSafe(
			'test',
			'T',
			[uint32(60), uint32(12), uint32(50), uint32(80)],
			voters,
			initialExtensions
		);

		moduleAddress = address(forumModule);
		safeAddress = address(safe);

		mockErc20_2 = new MockERC20('MockERC20_2', 'M20_2', 18);

		// Mint group some assets
		vm.deal(safeAddress, 1 ether);
		mockErc20.mint(safeAddress, 1 ether);
		mockErc20_2.mint(safeAddress, 1 ether);
		mockErc721.mint(safeAddress, 1);
		mockErc1155.mint(safeAddress, 1, 1, '');

		// Set mock ERC20 as a withdrawal token, and set allowances for both tokens
		tokens.push(address(mockErc20));
		vm.startPrank(moduleAddress, moduleAddress);
		forumWithdrawal.setExtension(abi.encode(tokens, uint256(WITHDRAWAL_START)));
		mockErc20.approve(address(forumWithdrawal), 1 ether);
		mockErc20_2.approve(address(forumWithdrawal), 1 ether);
		groupShareManager.mintShares(moduleAddress, alice, TOKEN, 1 ether);
		vm.stopPrank();
	}

	// /// -----------------------------------------------------------------------
	// /// Setup Extension
	// /// -----------------------------------------------------------------------

	// function testCannotSetEmptyWithdrawalsArray() public {
	// 	vm.expectRevert(bytes4(keccak256('NullTokens()')));
	// 	forumWithdrawal.setExtension(abi.encode(new address[](0), WITHDRAWAL_START));
	// }

	// function testSetExtension() public {
	// 	// Set mock ERC20 as a withdrawal token
	// 	vm.prank(moduleAddress, moduleAddress);
	// 	forumWithdrawal.setExtension(abi.encode(tokens, uint256(WITHDRAWAL_START)));

	// 	// Check that the withdrawal token is set
	// 	assertEq(
	// 		forumWithdrawal.withdrawables(moduleAddress, 0),
	// 		address(mockErc20),
	// 		'Withdrawal token not set'
	// 	);
	// }

	// /// -----------------------------------------------------------------------
	// /// Call Extension
	// /// -----------------------------------------------------------------------

	// function testCannotWithdrawBeforeStartTime() public {
	// 	// Edit start time into future
	// 	vm.prank(moduleAddress, moduleAddress);
	// 	forumWithdrawal.setExtension(abi.encode(tokens, uint256(WITHDRAWAL_START + 1000)));

	// 	// Check that the withdrawal fails before the deadline, but works after
	// 	vm.startPrank(alice, alice);
	// 	vm.expectRevert(bytes4(keccak256('NotStarted()')));
	// 	forumModule.callExtension(address(forumWithdrawal), 100, '0x00');
	// 	skip(1001);
	// 	forumModule.callExtension(address(forumWithdrawal), 1, '0x00');
	// }

	// /// @dev Covers case of non member trying to withdraw from group
	// function testCannotWithdrawMoreThanGroupTokenBalance() public {
	// 	// Check that the withdrawal fails if not enough group balance
	// 	vm.expectRevert(bytes4(keccak256('IncorrectAmount()')));
	// 	vm.prank(alice, alice);
	// 	forumModule.callExtension(address(forumWithdrawal), 10001, '0x00');

	// 	// Check balances after failed attempt, all unchanged
	// 	assertEq(mockErc20.balanceOf(moduleAddress), 1 ether);
	// 	assertEq(mockErc20.balanceOf(alice), 0);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), 1 ether);
	// }

	// function testAddTokenToWithdrawals() public {
	// 	// Check current withdrawal token
	// 	assertEq(
	// 		forumWithdrawal.withdrawables(moduleAddress, 0),
	// 		address(mockErc20),
	// 		'Withdrawal token not set'
	// 	);

	// 	// Add new token to withdrawals
	// 	address[] memory newTokens = new address[](1);
	// 	newTokens[0] = address(mockErc20_2);
	// 	vm.prank(moduleAddress, moduleAddress);
	// 	forumWithdrawal.addTokens(newTokens);

	// 	// Check that the withdrawal token is set
	// 	assertEq(
	// 		forumWithdrawal.withdrawables(moduleAddress, 1),
	// 		address(mockErc20_2),
	// 		'Withdrawal token not set'
	// 	);
	// }

	// function testRemoveTokenFromWithdrawals() public {
	// 	// Check current withdrawal token
	// 	assertEq(
	// 		forumWithdrawal.withdrawables(moduleAddress, 0),
	// 		address(mockErc20),
	// 		'Withdrawal token not set'
	// 	);

	// 	// Remove token from withdrawals
	// 	uint256[] memory removalTokens = new uint256[](1);
	// 	removalTokens[0] = uint256(0);
	// 	vm.prank(moduleAddress, moduleAddress);
	// 	forumWithdrawal.removeTokens(removalTokens);

	// 	// Check that the withdrawal token is set
	// 	assert(forumWithdrawal.getWithdrawables(moduleAddress).length == 0);
	// }

	// function testFuzzCallExtensionBasicWithdrawal(uint256 amount) public {
	// 	vm.assume(amount <= 10000);

	// 	// Check init balances
	// 	assertEq(mockErc20.balanceOf(moduleAddress), 1 ether);
	// 	assertEq(mockErc20.balanceOf(alice), 0);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), 1 ether);

	// 	uint256 redeemedAmount = redeemedAmountFromInputAmount(amount, alice);

	// 	vm.prank(alice, alice);
	// 	forumModule.callExtension(address(forumWithdrawal), amount, '0x00');

	// 	// Check balances after erc20 withdrawal
	// 	assertEq(mockErc20.balanceOf(moduleAddress), (1 ether - redeemedAmount));
	// 	assertEq(mockErc20.balanceOf(alice), redeemedAmount);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), (1 ether - redeemedAmount));
	// }

	// function testCallExtensionBasicMultipleWithdrawalTokens(uint256 amount) public {
	// 	vm.assume(amount <= 10000);

	// 	// Check init balances
	// 	assertEq(mockErc20.balanceOf(moduleAddress), 1 ether);
	// 	assertEq(mockErc20_2.balanceOf(moduleAddress), 1 ether);
	// 	assertEq(mockErc20.balanceOf(alice), 0);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), 1 ether);

	// 	// Add new token to withdrawals
	// 	address[] memory newTokens = new address[](1);
	// 	newTokens[0] = address(mockErc20_2);
	// 	vm.prank(moduleAddress, moduleAddress);
	// 	forumWithdrawal.addTokens(newTokens);

	// 	uint256 redeemedAmount = redeemedAmountFromInputAmount(amount, alice);

	// 	vm.prank(alice, alice);
	// 	forumModule.callExtension(address(forumWithdrawal), amount, '0x00');

	// 	// Check balances after erc20 withdrawal
	// 	assertEq(mockErc20.balanceOf(moduleAddress), (1 ether - redeemedAmount));
	// 	assertEq(mockErc20_2.balanceOf(moduleAddress), (1 ether - redeemedAmount));
	// 	assertEq(mockErc20.balanceOf(alice), redeemedAmount);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), (1 ether - redeemedAmount));
	// }

	// /// -----------------------------------------------------------------------
	// /// Custom Withdrawal
	// /// -----------------------------------------------------------------------

	// // A withdrawal of a non approved token via a custom proposal
	// function testSubmitCustomWithdrawal() public {
	// 	// Set one of each type ot token to test
	// 	address[] memory accounts = new address[](3);
	// 	accounts[0] = address(mockErc721);
	// 	accounts[1] = address(mockErc1155);
	// 	accounts[2] = address(mockErc20);

	// 	// SOme amounts of each token to test
	// 	uint256[] memory amounts = new uint256[](3);
	// 	amounts[0] = uint256(1);
	// 	amounts[1] = uint256(1);
	// 	amounts[2] = uint256(100);

	// 	// Create custom withdrawal
	// 	vm.prank(alice, alice);
	// 	forumWithdrawal.submitWithdrawlProposal(
	// 		IForumGroup(moduleAddress),
	// 		accounts,
	// 		amounts,
	// 		100
	// 	);

	// 	(
	// 		address[] memory withdrawalAssets,
	// 		uint256[] memory withdrawalAmounts,
	// 		uint256 amountToBurn
	// 	) = forumWithdrawal.getCustomWithdrawals(moduleAddress, alice);

	// 	assertEq(withdrawalAssets, accounts);
	// 	assertEq(withdrawalAmounts, amounts);
	// 	assertEq(amountToBurn, 100);
	// }

	// function testCannotWithdrawMoreThanErc20Balance() public {
	// 	address[] memory accounts = new address[](1);
	// 	accounts[0] = address(mockErc20);

	// 	uint256[] memory amounts = new uint256[](1);
	// 	amounts[0] = uint256(1 ether + 1);

	// 	// Create custom withdrawal
	// 	vm.prank(alice, alice);
	// 	forumWithdrawal.submitWithdrawlProposal(
	// 		IForumGroup(moduleAddress),
	// 		accounts,
	// 		amounts,
	// 		100
	// 	);

	// 	processProposal(1, forumModule, false);

	// 	// Check balances after fail, all unchanged
	// 	assertEq(mockErc20.balanceOf(moduleAddress), 1 ether);
	// 	assertEq(mockErc20.balanceOf(alice), 0);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), 1 ether);
	// }

	// function testCannotWithdrawNonOwnedErc721() public {
	// 	address[] memory accounts = new address[](1);
	// 	accounts[0] = address(mockErc721);

	// 	uint256[] memory amounts = new uint256[](1);
	// 	amounts[0] = uint256(2);

	// 	// Create custom withdrawal
	// 	vm.prank(alice, alice);
	// 	forumWithdrawal.submitWithdrawlProposal(
	// 		IForumGroup(moduleAddress),
	// 		accounts,
	// 		amounts,
	// 		100
	// 	);

	// 	processProposal(1, forumModule, false);

	// 	// Check balances after erc721 withdrawal
	// 	assertEq(mockErc721.balanceOf(moduleAddress), 1);
	// 	assertEq(mockErc721.balanceOf(alice), 0);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), 1 ether);
	// }

	// // A withdrawal of a non approved token via a custom proposal
	// function testProcessCustomWithdrawal(uint256 erc20Amount, uint256 burnAmount) public {
	// 	vm.assume(erc20Amount <= 1 ether && burnAmount <= 1 ether);

	// 	// Check init balances
	// 	assertEq(mockErc20.balanceOf(moduleAddress), 1 ether);
	// 	assertEq(mockErc20.balanceOf(alice), 0);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), 1 ether);

	// 	address[] memory accounts = new address[](3);
	// 	accounts[0] = address(mockErc721);
	// 	accounts[1] = address(mockErc1155);
	// 	accounts[2] = address(mockErc20);

	// 	uint256[] memory amounts = new uint256[](3);
	// 	amounts[0] = uint256(1);
	// 	amounts[1] = uint256(1);
	// 	amounts[2] = erc20Amount;

	// 	// Create custom withdrawal
	// 	vm.prank(alice, alice);
	// 	forumWithdrawal.submitWithdrawlProposal(
	// 		IForumGroup(moduleAddress),
	// 		accounts,
	// 		amounts,
	// 		burnAmount
	// 	);

	// 	processProposal(1, forumModule, true);

	// 	// Check balances after erc721 withdrawal
	// 	// assertEq(mockErc20.balanceOf(moduleAddress), 900);
	// 	assertEq(mockErc721.balanceOf(alice), 1);
	// 	assertEq(mockErc1155.balanceOf(alice, 1), 1);
	// 	assertEq(mockErc20.balanceOf(alice), erc20Amount);
	// 	assertEq(forumModule.balanceOf(alice, TOKEN), (1 ether - burnAmount));
	// }

	// /// -----------------------------------------------------------------------
	// /// Utils
	// /// -----------------------------------------------------------------------

	// function redeemedAmountFromInputAmount(
	// 	uint256 amount,
	// 	address member
	// ) internal view returns (uint256 redeemedAmount) {
	// 	// Token amount to be withdrawn, given the 'amount' (%) in basis points of 10000
	// 	uint256 tokenAmount = (amount * forumModule.balanceOf(member, 1)) / 10000;

	// 	redeemedAmount =
	// 		(tokenAmount * mockErc20.balanceOf(moduleAddress)) /
	// 		forumModule.totalSupply();
	// }
}
