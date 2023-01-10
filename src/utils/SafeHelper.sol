// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// ! fix remappings failings with hardhat
import {Module, Enum} from '@gnosis.pm/zodiac/contracts/core/Module.sol';

abstract contract SafeHelper is Module {
	/// ----------------------------------------------------------------------------------------
	///							GNOSIS SAFE STORAGE
	/// ----------------------------------------------------------------------------------------

	// Gnosis multisendLibrary library contract
	address public multisendLibrary;

	// Used in staticcall to ganosis safe - bytes4(keccak256('getThreshold()'))
	bytes internal constant GET_THRESHOLD = abi.encodeWithSelector(0xe75235b8);

	// Function sig for isOwner - bytes4(keccak256('isOwner(address)'))
	bytes4 internal constant IS_OWNER_SIG = 0x2f54bf6e;

	/// ----------------------------------------------------------------------------------------
	///							GNOSIS SAFE STORAGE
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

		return bytes32(_isOwner) == bytes32(uint256(1));
	}
}
