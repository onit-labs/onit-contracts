// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

contract SafeHelper {
	/// ----------------------------------------------------------------------------------------
	///							GNOSIS SAFE STORAGE
	/// ----------------------------------------------------------------------------------------

	// Gnosis multisendLibrary library contract
	address public multisendLibrary;

	// Used in staticcall to ganosis safe - bytes4(keccak256('getThreshold()'))
	bytes internal constant GET_THRESHOLD = abi.encodeWithSelector(0xe75235b8);

	// Function sig for call to safe - bytes4(keccak256('addOwnerWithThreshold(address,uint256)'))
	bytes4 internal constant ADD_OWNER_WITH_THRESHOLD_SIG = 0x0d582f13;

	/// ----------------------------------------------------------------------------------------
	///							GNOSIS SAFE STORAGE
	/// ----------------------------------------------------------------------------------------

	function getThreshold(address _safe) public view returns (uint256) {
		(, bytes memory threshold) = _safe.staticcall(GET_THRESHOLD);

		return uint256(bytes32(threshold));
	}
}
