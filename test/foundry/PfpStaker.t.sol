// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PfpSetter} from '../../src/gnosis-forum/extensions/pfp-setter/PfpSetter.sol';

import {ERC721Test} from '../../src/test-contracts/ERC721Test.sol';
import {ERC1155Test} from '../../src/test-contracts/ERC1155Test.sol';

import 'forge-std/Test.sol';
import 'forge-std/StdCheats.sol';

contract WithdrawalTest is Test {
	PfpSetter public pfpStaker;

	ERC721Test public mockErc721;
	ERC1155Test public mockErc1155;

	address internal alice;
	uint256 internal alicePk;
	address internal bob;
	uint256 internal bobPk;

	address[] internal tokens;

	address internal pfpStore;

	uint256 internal constant MEMBERSHIP = 0;
	uint256 internal constant TOKEN = 1;

	uint256 internal WITHDRAWAL_START = block.timestamp;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	function setUp() public {
		(alice, alicePk) = makeAddrAndKey('alice');
		(bob, bobPk) = makeAddrAndKey('bob');

		pfpStore = address(0x1);

		pfpStaker = new PfpSetter(pfpStore);
		mockErc721 = new ERC721Test('MockERC721', 'M721');
		mockErc1155 = new ERC1155Test('MockERC1155', 'M1155');

		mockErc721.mint(alice, 1);
		mockErc1155.mint(alice, 1, 1);
	}

	/// -----------------------------------------------------------------------
	/// Setup Extension
	/// -----------------------------------------------------------------------

	// Test setting the pfpStore address
	function testSetPfpStore() public {
		vm.prank(alice, alice);
		assertEq(pfpStaker.pfpStore(), pfpStore);

		// Test that only the owner can set the pfpStore
		vm.prank(bob, bob);
		vm.expectRevert('UNAUTHORISED');
		assertEq(pfpStaker.pfpStore(), pfpStore);
	}

	/// -----------------------------------------------------------------------
	/// Staking Nfts
	/// -----------------------------------------------------------------------

	// Stake should fail if not sent by staker, or pfpStore, pass otherwise
	function testStakeNft() public {
		pfpStaker.stakeNft(address(mockErc1155), 1);

		// Fail if not sent by pfpStore
		vm.prank(bob, bob);
		vm.expectRevert(bytes4(keccak256('Unauthorised()')));
		pfpStaker.stakeNft(address(mockErc1155), 1);
		assertEq(pfpStaker.pfpStore(), address(0), 'Should be 0');
	}

	/// -----------------------------------------------------------------------
	/// Token Uris
	/// -----------------------------------------------------------------------

	// When no nft is staked
	function testGetBaseURI() public {
		vm.prank(alice, alice);
		mockErc721.approve(address(pfpStaker), 1);

		console.log(pfpStaker.getUri(alice, 'test', 0));
	}

	// When nft is staked
	function testURIWithStakedNft() public {
		vm.prank(alice, alice);
		mockErc721.approve(address(pfpStaker), 1);

		pfpStaker.getUri(alice, 'test', 0);
	}
}
