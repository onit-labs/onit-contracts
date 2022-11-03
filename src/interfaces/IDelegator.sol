// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @notice Allows members to stake group tokens and assign voting power to others
interface IDelegator {
	struct Delegate {
		bool direction; // true = delegator, false = delegatee
		address account;
		uint256 amount;
		uint256 atProposal;
	}

	function delegators(address, address) external returns (Delegate calldata);

	function delegatees(address, address) external returns (Delegate calldata);
}
