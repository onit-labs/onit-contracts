// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @dev Access Level Manager for forum
interface IAccessManager {
	enum AccessLevels {
		NONE,
		BASIC,
		BRONZE,
		SILVER,
		GOLD
	}

	// resaleRoyalty is based off 10000 basis points (eg. resaleRoyalty = 100 => 1.00%)
	struct Item {
		bool live;
		uint256 price;
		uint256 maxSupply;
		uint256 currentSupply;
		uint256 accessLevel;
		uint256 resaleRoyalty;
	}

	function memberLevel(address) external view returns (uint256);

	function forumWhitelist(address, uint256) external view returns (bool);

	function toggleItemWhitelist(address, uint256) external;

	function addItem(
		uint256 price,
		uint256 itemSupply,
		uint256 accessLevel,
		uint256 resaleRoyalty
	) external;

	function mintItem(uint256, address) external payable;
}
