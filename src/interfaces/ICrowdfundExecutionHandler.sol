// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @notice ICrowdfundExecutionHandler interface.

interface ICrowdfundExecutionHandler {
	function handleCrowdfundExecution(
		address crowdfundContract,
		address assetContract,
		address forumGroup,
		uint256 tokenId,
		bytes calldata payload
	) external view returns (uint256, bytes memory);
}
