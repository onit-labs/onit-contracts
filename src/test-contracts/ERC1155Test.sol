// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.13;

import '../utils/tokens/erc1155/ERC1155.sol';

/// @dev THIS IS A TEST FILE ONLY
contract ERC1155Test is ERC1155 {
	string public name;

	string public symbol;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

	constructor(string memory name_, string memory symbol_) ERC1155() {
		name = name_;
		symbol = symbol_;
	}

	function mint(address to, uint256 id, uint256 amount) public {
		_mint(to, id, amount, '');
	}

	function uri(uint256 id) public view override returns (string memory) {
		return 'TEST URI';
	}
}
