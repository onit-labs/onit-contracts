// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {Owned} from '../../utils/Owned.sol';

import {ICrowdfundExecutionHandler} from '../../interfaces/ICrowdfundExecutionHandler.sol';
import {ICrowdfundExecutionManager} from '../../interfaces/ICrowdfundExecutionManager.sol';
import {IERC20} from '../../interfaces/IERC20.sol';

import 'hardhat/console.sol';

/**
 * @title CrowdfundExecutionManager
 * @notice It allows adding/removing executionHandlers to manage crowdfund executions.
 * @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)
 */
contract CrowdfundExecutionManager is ICrowdfundExecutionManager, Owned {
	/// ----------------------------------------------------------------------------------------
	///							ERRORS & EVENTS
	/// ----------------------------------------------------------------------------------------

	error UnsupportedTarget();

	error TransferFailed();

	event ExecutionHandlerUpdated(
		address indexed handledAddress,
		address indexed newExecutionHandler
	);

	event ExecutionHandlerAdded(
		address indexed newHandledAddress,
		address indexed executionHandler
	);

	/// ----------------------------------------------------------------------------------------
	///							ExecutionManager Storage
	/// ----------------------------------------------------------------------------------------

	/// @notice Each executionHandler is an address with logic to extract the details of the execution, for example asset price, contract address, etc.
	mapping(address => address) public executionHandlers;

	/// ----------------------------------------------------------------------------------------
	///							Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(address deployer) Owned(deployer) {}

	/// ----------------------------------------------------------------------------------------
	///							Owner Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Add a executionHandler
	 * @param newHandledAddress address of contract to handle executions for
	 * @param executionHandler address of the executionHandler
	 */
	function addExecutionHandler(address newHandledAddress, address executionHandler)
		external
		onlyOwner
	{
		executionHandlers[newHandledAddress] = executionHandler;
		emit ExecutionHandlerAdded(newHandledAddress, executionHandler);
	}

	/**
	 * @notice Update a executionHandler
	 * @param handledAddress address of the contract which we handle executions for
	 * @param newExecutionHandler address of the updated handler
	 */
	function updateExecutionHandler(address handledAddress, address newExecutionHandler)
		external
		onlyOwner
	{
		executionHandlers[handledAddress] = newExecutionHandler;

		emit ExecutionHandlerUpdated(handledAddress, newExecutionHandler);
	}

	/**
	 * @notice Collect native fees
	 * @dev This is not onlyOwner to enable automation of the fee collection.
	 */
	function collectFees() external {
		(bool success, ) = payable(owner).call{value: address(this).balance}(new bytes(0));
		if (!success) revert TransferFailed();
	}

	/**
	 * @notice Collect token fees
	 * @dev This is not onlyOwner to enable automation of the fee collection.
	 */
	function collectERC20(IERC20 erc20) external {
		IERC20(erc20).transfer(owner, erc20.balanceOf(address(this)));
	}

	/// ----------------------------------------------------------------------------------------
	///							Public Interface
	/// ----------------------------------------------------------------------------------------

	// ! consider more tidy way to get props into executionHandler
	/**
	 * @notice Manage the routing to an executionHandler based on the contract
	 * @param payload payload sent to contract which will be decoded
	 * @param forumGroup contract address
	 */
	function manageExecution(
		address crowdfundContract,
		address targetContract,
		address assetContract,
		address forumGroup,
		uint256 tokenId,
		bytes calldata payload
	) external view returns (uint256, bytes memory) {
		console.logBytes4(type(IERC20).interfaceId);
		console.logAddress(executionHandlers[targetContract]);

		// If the target has a handler, use it
		if (executionHandlers[targetContract] != address(0))
			return
				ICrowdfundExecutionHandler(executionHandlers[targetContract])
					.handleCrowdfundExecution(
						crowdfundContract,
						assetContract,
						forumGroup,
						tokenId,
						payload
					);

		revert UnsupportedTarget();
	}

	receive() external payable virtual {}
}
