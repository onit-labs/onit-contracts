// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {OrderTypes} from '../libraries/OrderTypes.sol';

/**
 * @title JoepegsProposalHandler
 * @notice Handles decoding of proposals for Joepegs Marketplace
 */
contract JoepegsProposalHandler {
	/// ----------------------------------------------------------------------------------------
	///							ExecutionManager Storage
	/// ----------------------------------------------------------------------------------------

	error InvalidFunction();

	/// Mappings to decide which funcitons are free/commission
	/// bytes4 key is the function signature
	mapping(bytes4 => uint256) public commissionFreeFunctions;
	mapping(bytes4 => uint256) public commissionBasedFunctions;

	uint256 public immutable PROTOCOL_FEE;

	/// ----------------------------------------------------------------------------------------
	///							Constructor
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Constructor
	 * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
	 */
	constructor(
		uint256 _protocolFee,
		bytes4[] memory _commissionFreeFunctions,
		bytes4[] memory _commissionBasedFunctions
	) {
		PROTOCOL_FEE = _protocolFee;

		// Set the functions that are enabled -> 1 for enabled
		for (uint256 i; i < _commissionFreeFunctions.length; i++) {
			commissionFreeFunctions[_commissionFreeFunctions[i]] = 1;
		}

		for (uint256 i; i < _commissionBasedFunctions.length; i++) {
			commissionBasedFunctions[_commissionBasedFunctions[i]] = 1;
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							Public Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Decides commission to charge based on the function being called.
	 *     		 Since all on-chain joe functions decode a TakerOrder, we can do
	 *     		 everything in handleProposal.
	 * @param value not used in this contract, keeps interface consistent with other handlers
	 * @return payload to decode and extract commission info from
	 */
	function handleProposal(uint256 value, bytes calldata payload) external view returns (uint256) {
		// Extract function sig from payload as the first 4 bytes
		bytes4 functionSig = bytes4(payload[0:4]);

		// If commissoin free retun 0
		if (commissionFreeFunctions[functionSig] == 1) return 0;

		// If commission based, calculate the commission
		if (commissionBasedFunctions[functionSig] == 1) {
			OrderTypes.TakerOrder memory TakerOrder = abi.decode(payload[4:], (OrderTypes.TakerOrder));

			// Return commission fee based of PROTOCOL_FEE and 10000 basis points
			return (TakerOrder.price * PROTOCOL_FEE) / 10000;
		}

		// If function is not listed, revert
		revert InvalidFunction();
	}

	/**
	 * @notice Return protocol fee for this proposal handler
	 * @return protocol fee
	 */
	function viewProtocolFee() external view returns (uint256) {
		return PROTOCOL_FEE;
	}
}
