// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.13;

import '../utils/tokens/erc721/ERC721.sol';

/// @dev THIS IS A TEST FILE ONLY
contract ERC721Test is ERC721 {
	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

	constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

	function mint(address to, uint256 id) public payable {
		_mint(to, id);
	}

	function tokenURI(uint256 id) public view override returns (string memory) {
		return 'TEST URI';
	}
}
