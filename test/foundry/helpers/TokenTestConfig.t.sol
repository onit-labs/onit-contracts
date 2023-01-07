// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MockERC20} from '@solbase/test/utils/mocks/MockERC20.sol';
import {MockERC721} from '@solbase/test/utils/mocks/MockERC721.sol';
import {MockERC1155} from '@solbase/test/utils/mocks/MockERC1155.sol';

// Config to import already setup tokens to other tests
abstract contract TokenTestConfig {
	MockERC20 public mockErc20;
	MockERC721 public mockErc721;
	MockERC1155 public mockErc1155;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	constructor() {
		mockErc20 = new MockERC20('MockERC20', 'M20', 18);
		mockErc721 = new MockERC721('MockERC721', 'M721');
		mockErc1155 = new MockERC1155();
	}
}
