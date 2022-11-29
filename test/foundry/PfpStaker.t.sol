// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PfpStaker} from '../../src/PfpStaker/PfpStaker.sol';

import {ERC721Test} from '../../src/Test/ERC721Test.sol';

import 'forge-std/Test.sol';
import 'forge-std/StdCheats.sol';

contract WithdrawalTest is Test {
	PfpStaker public pfpStaker;
	ERC721Test public mockErc721;

	address internal alice;
	uint256 internal alicePk;

	address[] internal tokens;

	uint256 internal constant MEMBERSHIP = 0;
	uint256 internal constant TOKEN = 1;

	uint256 internal WITHDRAWAL_START = block.timestamp;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		(alice, alicePk) = makeAddrAndKey('alice');

		pfpStaker = new PfpStaker();
		mockErc721 = new ERC721Test('MockERC721', 'M721');

		mockErc721.mint(alice, 1);
	}

	/// -----------------------------------------------------------------------
	/// Setup Extension
	/// -----------------------------------------------------------------------

	// When no nft is staked
	function testGetBaseURI() public {
		vm.prank(alice, alice);
		mockErc721.approve(address(pfpStaker), 1);

		pfpStaker.getURI(alice, 'test');
	}
}
