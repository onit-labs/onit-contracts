// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {Owned} from '../utils/Owned.sol';

import {IExecutionManager} from '../interfaces/IExecutionManager.sol';
import {IProposalHandler} from '../interfaces/IProposalHandler.sol';
import {IERC20} from '../interfaces/IERC20.sol';

/**
 * @title ExecutionManager
 * @notice It allows adding/removing proposalHandlers to collect fees from proposals.
 * @author Modified from Looksrare (https://github.com/LooksRare/contracts-exchange-v1/blob/master/contracts/ExecutionManager.sol)
 */
contract ExecutionManager is IExecutionManager, Owned {
	/// ----------------------------------------------------------------------------------------
	///							ERRORS & EVENTS
	/// ----------------------------------------------------------------------------------------

	error TransferFailed();

	error UnapprovedContract();

	event ProposalHandlerUpdated(address indexed handledAddress, address indexed newProposalHandler);

	event ProposalHandlerAdded(address indexed newHandledAddress, address indexed proposalHandler);

	event BaseCommissionToggled(uint256 indexed newBaseCommission);

	event NonCommissionContracts(address contractAddress, bool newCommissionSetting);

	/// ----------------------------------------------------------------------------------------
	///							ExecutionManager Storage
	/// ----------------------------------------------------------------------------------------

	/// @notice If equal to 1 then only certain contracts can be called
	uint256 public baseCommission = 1;

	/// @notice Each proposalHandler is an address with logic to extract the details of the proposal to take commission fees from.
	mapping(address => address) public proposalHandlers;

	/// @notice A set of contracts for which no commission is taken
	mapping(address => bool) public nonCommissionContracts;

	/// ----------------------------------------------------------------------------------------
	///							Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(address deployer) Owned(deployer) {}

	/// ----------------------------------------------------------------------------------------
	///							Owner Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Add a proposalHandler
	 * @param newHandledAddress address of contract to handle proposals for
	 * @param proposalHandler address of the proposalHandler
	 */
	function addProposalHandler(address newHandledAddress, address proposalHandler)
		external
		onlyOwner
	{
		proposalHandlers[newHandledAddress] = proposalHandler;
		emit ProposalHandlerAdded(newHandledAddress, proposalHandler);
	}

	/**
	 * @notice Update a proposalHandler
	 * @param handledAddress address of the contract which we handle proposals for
	 * @param newProposalHandler address of the updated handler
	 */
	function updateProposalHandler(address handledAddress, address newProposalHandler)
		external
		onlyOwner
	{
		proposalHandlers[handledAddress] = newProposalHandler;

		emit ProposalHandlerUpdated(handledAddress, newProposalHandler);
	}

	/**
	 * @notice Change the baseCommission setting
	 * @param _baseCommission new base commission setting, used for non configured contracts (1 = on, 0 = off)
	 */
	function setBaseCommission(uint256 _baseCommission) external onlyOwner {
		baseCommission = _baseCommission;

		emit BaseCommissionToggled(_baseCommission);
	}

	/**
	 * @notice Add/Remove a non-commission contract
	 * @param nonCommissionContract address of contract to not charge commission on
	 */
	function toggleNonCommissionContract(address nonCommissionContract) external onlyOwner {
		nonCommissionContracts[nonCommissionContract] = !nonCommissionContracts[nonCommissionContract];
		emit NonCommissionContracts(
			nonCommissionContract,
			nonCommissionContracts[nonCommissionContract]
		);
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

	/**
	 * @notice Manage the routing to a proposalHandler based on the contract
	 * @param target target contract for proposal
	 * @param value value of tx
	 * @param payload payload sent to contract which will be decoded
	 */
	function manageExecution(
		address target,
		uint256 value,
		bytes memory payload
	) external view returns (uint256) {
		// If the target has a handler, use it
		if (proposalHandlers[target] != address(0))
			return IProposalHandler(proposalHandlers[target]).handleProposal(value, payload);

		// If baseCommission is off or the target is nonCommission return 0,
		if (baseCommission == 0 || nonCommissionContracts[target]) return 0;

		// else revert
		if (baseCommission == 1) return gasleft();
	}

	receive() external payable virtual {}
}
