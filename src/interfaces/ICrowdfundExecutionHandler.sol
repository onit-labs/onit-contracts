// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @notice ICrowdfundExecutionHandler interface.

interface ICrowdfundExecutionHandler {
	function handleCrowdfundExecution(address forumGroup, bytes memory payload)
		external
		view
		returns (
			address,
			uint256,
			bytes memory
		);
}
