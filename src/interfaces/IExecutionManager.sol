// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @notice Execution Manager interface.
/// @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)

interface IExecutionManager {
	function addProposalHandler(address newHandledAddress, address handlerAddress) external;

	function updateProposalHandler(address proposalHandler, address newProposalHandler) external;

	function manageExecution(
		address target,
		uint256 value,
		bytes memory payload
	) external returns (uint256);
}
