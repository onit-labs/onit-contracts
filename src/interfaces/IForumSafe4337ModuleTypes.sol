// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// @notice Forum module interface for sharing types
interface IForumSafeModuleTypes {
	enum ProposalType {
		CALL, // call contracts
		MEMBER_THRESHOLD, // set `memberVoteThreshold`
		TOKEN_THRESHOLD, // set `tokenVoteThreshold`
		TYPE, // set `VoteType` to `ProposalType`
		PAUSE, // flip membership transferability
		EXTENSION, // flip `extensions` whitelisting
		DOCS // amend org docs
	}

	enum VoteType {
		MEMBER, // % of members required to pass
		SIMPLE_MAJORITY, // over 50% total votes required to pass
		TOKEN_MAJORITY // user set % of total votes required to pass
	}
}
