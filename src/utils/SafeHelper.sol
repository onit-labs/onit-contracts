// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {Module, Enum} from '@zodiac/core/Module.sol';

abstract contract SafeHelper is Module {
	/// ----------------------------------------------------------------------------------------
	///							SAFE HELPER STORAGE
	/// ----------------------------------------------------------------------------------------

	error AvatarOnly();

	error ExecuteAsModuleError();

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

	/// ----------------------------------------------------------------------------------------
	///							MODULE LOGIC
	/// ----------------------------------------------------------------------------------------

	modifier avatarOnly() {
		if (msg.sender != avatar) revert AvatarOnly();
		_;
	}

	/**
	 * @notice Execute a transaction as a module
	 * @dev Can be used to execute arbitrary code if needed, only when called by safe
	 * @param _to address to send transaction to
	 * @param _value value to send with transaction
	 * @param _data data to send with transaction
	 */
	function executeAsModule(
		address _to,
		uint256 _value,
		bytes calldata _data
	) external avatarOnly {
		(bool success, ) = _to.call{value: _value}(_data);
		if (!success) revert ExecuteAsModuleError();
	}
}
