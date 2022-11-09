// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/// @notice Crowdfund Execution Manager interface.
/// @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)

interface ICrowdfundExecutionManager {
	function addExecutionHandler(address newHandledAddress, address handlerAddress) external;

	function updateExecutionHandler(address proposalHandler, address newProposalHandler) external;

	function manageExecution(
		address forumGroup,
		address target,
		bytes memory payload
	)
		external
		returns (
			address,
			uint256,
			bytes memory
		);
}
