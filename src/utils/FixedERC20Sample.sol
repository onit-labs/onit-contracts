// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './FixedERC20.sol';

contract FixedERC20Sample is FixedERC20 {
	uint256 public totalSupply;
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;
	string public name = 'DAI';
	string public symbol = 'DAI';
	uint8 public decimals = 18;

	function transfer(address recipient, uint256 amount) external returns (bool) {
		balanceOf[msg.sender] -= amount;
		balanceOf[recipient] += amount;
		emit Transfer(msg.sender, recipient, amount);
		return true;
	}

	function approve(address spender, uint256 amount) external returns (bool) {
		allowance[msg.sender][spender] = amount;
		emit Approval(msg.sender, spender, amount);
		return true;
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool) {
		allowance[sender][msg.sender] -= amount;
		balanceOf[sender] -= amount;
		balanceOf[recipient] += amount;
		emit Transfer(sender, recipient, amount);
		return true;
	}

	function mint(uint256 amount) external {
		balanceOf[msg.sender] += amount;
		totalSupply += amount;
		emit Transfer(address(0), msg.sender, amount);
	}

	function burn(uint256 amount) external {
		balanceOf[msg.sender] -= amount;
		totalSupply -= amount;
		emit Transfer(msg.sender, address(0), amount);
	}
}
