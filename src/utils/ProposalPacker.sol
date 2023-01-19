// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
 * @title ProposalPacker
 * @notice A contract that packs and unpacks proposals
 */
contract ProposalPacker {
	/**
	 * @notice packs proposaltype, creationtime, and operation type into a single uint256
	 * @param creationTime creation time
	 * @param proposalType proposal type
	 * @param operationType operation type
	 */
	function packProposal(
		uint32 creationTime,
		uint8 proposalType,
		uint8 operationType
	) internal pure returns (uint48) {
		return (uint48(creationTime) << 32) | (uint48(proposalType) << 8) | uint48(operationType);
	}

	/**
	 * @notice unpacks proposaltype, creationtime, and operation type from a single uint256
	 * @param proposal packed proposal
	 * @return creationTime creation time
	 * @return proposalType proposal type
	 * @return operationType operation type
	 * @dev //! consider making internal, depending on use
	 */
	function unpackProposal(
		uint48 proposal
	) public pure returns (uint32 creationTime, uint8 proposalType, uint8 operationType) {
		creationTime = uint32(proposal >> 32);
		proposalType = uint8(proposal >> 8);
		operationType = uint8(proposal);
	}
}
