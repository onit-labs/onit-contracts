// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @notice ProposalHandler interface.

interface IProposalHandler {
	function handleProposal(uint256 value, bytes memory payload) external view returns (uint256);
}
