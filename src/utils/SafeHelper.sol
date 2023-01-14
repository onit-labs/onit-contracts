// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// ! fix remappings failings with hardhat
import {Module, Enum} from '@gnosis.pm/zodiac/contracts/core/Module.sol';

abstract contract SafeHelper is Module {
	/// ----------------------------------------------------------------------------------------
	///							GNOSIS SAFE STORAGE
	/// ----------------------------------------------------------------------------------------

	// Gnosis multisendLibrary library contract
	address public multisendLibrary;

	// Used in staticcall to gnosis safe - bytes4(keccak256('getThreshold()'))
	bytes internal constant GET_THRESHOLD = abi.encodeWithSelector(0xe75235b8);

	//  Used in staticcall to gnosis safe - bytes4(keccak256('getOwners()'))
	bytes internal constant GET_OWNERS = abi.encodeWithSelector(0xa0e67e2b);

	// Function sig for isOwner - bytes4(keccak256('isOwner(address)'))
	bytes4 internal constant IS_OWNER_SIG = 0x2f54bf6e;

	/// ----------------------------------------------------------------------------------------
	///							GNOSIS SAFE LOGIC
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Sets the multisend library address
	 * @return threshold for votes on the safe
	 */
	function getThreshold() public view returns (uint256) {
		(, bytes memory threshold) = target.staticcall(GET_THRESHOLD);

		return uint256(bytes32(threshold));
	}

	/**
	 * @notice Checks if an address is an owner of the safe
	 * @param owner The address to check
	 * @return True if the address is an owner of the safe
	 */
	function isOwner(address owner) public view returns (bool) {
		(, bytes memory _isOwner) = target.staticcall(abi.encodeWithSelector(IS_OWNER_SIG, owner));

		// ! consider other way to get bool here
		return bytes32(_isOwner) == bytes32(uint256(1));
	}

	/**
	 * @notice Gets all owners on the safe
	 * @return owners on the safe
	 */
	function getOwners() public view returns (address[] memory) {
		(, bytes memory _owners) = target.staticcall(GET_OWNERS);

		return abi.decode(_owners, (address[]));
	}
}
