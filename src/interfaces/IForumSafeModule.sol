// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import './IForumSafeModuleTypes.sol';

/// @notice ForumSafeModule interface
interface IForumSafeModule {
	function propose(
		IForumSafeModuleTypes.ProposalType proposalType,
		address[] calldata accounts,
		uint256[] calldata amounts,
		bytes[] calldata payloads
	) external payable returns (uint256);

	function proposalCount() external payable returns (uint256);

	function mintShares(address to, uint256 id, uint256 amount) external payable;

	function burnShares(address from, uint256 id, uint256 amount) external payable;

	function balanceOf(address to, uint256 tokenId) external payable returns (uint256);

	function target() external payable returns (address);
}
