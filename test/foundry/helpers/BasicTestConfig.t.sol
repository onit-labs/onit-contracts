// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MockERC20} from '../../../lib/solbase/test/utils/mocks/MockERC20.sol';
import {MockERC721} from '../../../lib/solbase/test/utils/mocks/MockERC721.sol';
import {MockERC1155} from '../../../lib/solbase/test/utils/mocks/MockERC1155.sol';

import 'forge-std/Test.sol';
import 'forge-std/StdCheats.sol';
import 'forge-std/console.sol';

// Config to import already setup tokens and addresses to other tests
abstract contract BasicTestConfig is Test {
	MockERC20 public mockErc20;
	MockERC721 public mockErc721;
	MockERC1155 public mockErc1155;

	address internal alice;
	uint256 internal alicePk;
	address internal bob;
	uint256 internal bobPk;
	address internal carl;
	uint256 internal carlPk;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	constructor() {
		mockErc20 = new MockERC20('MockERC20', 'M20', 18);
		mockErc721 = new MockERC721('MockERC721', 'M721');
		mockErc1155 = new MockERC1155();

		(alice, alicePk) = makeAddrAndKey('alice');
		(bob, bobPk) = makeAddrAndKey('bob');
		(carl, carlPk) = makeAddrAndKey('carl');

		deal(alice, 1 ether);
		deal(bob, 1 ether);
		deal(carl, 1 ether);
	}
}
