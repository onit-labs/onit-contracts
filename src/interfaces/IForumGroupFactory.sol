// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @notice Forum Factory Interface.
interface IForumFactory {
	function deployGroup(
		string memory name_,
		string memory symbol_,
		address[] calldata voters_,
		uint8[4] memory govSettings_
	) external payable returns (address);
}
