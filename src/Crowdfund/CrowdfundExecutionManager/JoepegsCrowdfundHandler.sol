// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OrderTypes} from '../../libraries/OrderTypes.sol';

import {IERC165} from '../../interfaces/IERC165.sol';

// ! WIP
// Paused as collectionAddress is not in the TakerOrder struct
// Consider a similar approach for other similar functions that need decoded

/**
 * @title JoepegsCrowdfundHandler
 * @notice Handles decoding of crowdfund payload for Joepegs Marketplace
 */
contract JoepegsCrowdfundHandler {
	/// ----------------------------------------------------------------------------------------
	///							JoepegsCrowdfundHandler Storage
	/// ----------------------------------------------------------------------------------------

	error InvalidFunction();

	// ERC721 interfaceID
	bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
	// ERC1155 interfaceID
	bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

	/// bytes4 key is the function signature
	mapping(bytes4 => uint256) public enabledMethods;

	/// ----------------------------------------------------------------------------------------
	///							Constructor
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Constructor
	 * @param _protocolFee protocol fee (200 --> 2%, 400 --> 4%)
	 */
	constructor(uint256 _protocolFee, bytes4[] memory _enabledMethods) {
		// Set the functions that are enabled -> 1 for enabled
		for (uint256 i; i < _enabledMethods.length; i++) {
			enabledMethods[_enabledMethods[i]] = 1;
		}
	}

	/// ----------------------------------------------------------------------------------------
	///							Public Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Decides commission to charge based on the function being called.
	 *     		 Since all on-chain joe functions decode a TakerOrder, we can do
	 *     		 everything in handleCrowdfund.
	 * @param value not used in this contract, keeps interface consistent with other handlers
	 * @return payload to decode and extract commission info from
	 */
	function handleCrowdfund(uint256 value, bytes calldata payload)
		external
		view
		returns (uint256)
	{
		// Extract function sig from payload as the first 4 bytes
		bytes4 functionSig = bytes4(payload[0:4]);

		// If enabled method, decode the payload to the order details
		if (enabledMethods[functionSig] == 1) {
			OrderTypes.TakerOrder memory TakerOrder = abi.decode(
				payload[4:],
				(OrderTypes.TakerOrder)
			);

			// Check asset type in Transfer Selector
		}

		// If function is not listed, revert
		revert InvalidFunction();
	}
}
