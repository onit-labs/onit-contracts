// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import '@safe/common/SelfAuthorized.sol';

/// @title MemberManager - Manages a set of members and a voteThreshold to perform actions.
/// @author Forum (Modified from Safe OwnerManager by Stefan George - <stefan@gnosis.pm> & Richard Meissner - <richard@gnosis.pm>)
abstract contract MemberManager is SelfAuthorized {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event AddedMember(Member member);

	event RemovedMember(Member member);

	event ChangedVoteThreshold(uint256 voteThreshold);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error MemberExists();

	error CannotRemoveMember();

	error InvalidThreshold();

	/// ----------------------------------------------------------------------------------------
	///							MEMBER MANAGER STORAGE
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Member struct
	 * @param x Public key of member
	 * @param y Public key of next member
	 * @dev x & y are the public key of the members P-256 passkey
	 */
	struct Member {
		uint256 x;
		uint256 y;
	}

	// Number of required signatures for a Safe transaction.
	uint256 internal _voteThreshold;

	// Storing all members to index the mapping
	bytes32[] internal _membersHashArray;

	// ! consider making the key here an address & calcualting the address from the public key
	// This would require using the getAddress fn from the factory, or simplifying the factory
	// By removing salt from the account deployment, we could get a consistent address based only off the public key
	// The downside is that each passkey can only deply one account
	// The pro is that we can use the address as the key for the mapping, and use a real 1155 token
	mapping(bytes32 => Member) internal _members;

	/// ----------------------------------------------------------------------------------------
	///							MEMBER WRITE FUNCTIONS
	/// ----------------------------------------------------------------------------------------

	// ! consider visibility and access control
	/// @notice Changes the voteThreshold of the Safe to `voteThreshold`.
	/// @param voteThreshold New voteThreshold.
	function changeVoteThreshold(uint256 voteThreshold) public authorized {
		// Validate that voteThreshold is not bigger than number of members & is at least 1
		if (voteThreshold < 1 || voteThreshold > _membersHashArray.length)
			revert InvalidThreshold();

		_voteThreshold = voteThreshold;
		emit ChangedVoteThreshold(_voteThreshold);
	}

	/// @notice Adds a member to the Safe.
	/// @param member Member to add.
	/// @param voteThreshold_ New voteThreshold.
	function addMemberWithThreshold(
		Member memory member,
		uint256 voteThreshold_
	) public authorized {
		bytes32 memberHash = keccak256(abi.encodePacked(member.x, member.y));
		if (_members[memberHash].x != 0) revert MemberExists();

		// Validate that voteThreshold is at least 1 & is not bigger than (the new) number of members
		if (voteThreshold_ < 1 || voteThreshold_ > _membersHashArray.length + 1)
			revert InvalidThreshold();

		_members[memberHash] = member;
		_membersHashArray.push(memberHash);

		// Update voteThreshold
		_voteThreshold = voteThreshold_;

		// ! consider a nonce or similar to prevent replies (if sigs are used)
		emit AddedMember(member);
	}

	// ! improve handling of member array
	/// @notice Removes a member from the Safe & updates threshold.
	/// @param memberHash Hash of the member's public key.
	/// @param voteThreshold_ New voteThreshold.
	function removeMemberWithThreshold(
		bytes32 memberHash,
		uint256 voteThreshold_
	) public authorized {
		if (_members[memberHash].x == 0) revert CannotRemoveMember();

		// Validate that voteThreshold is at least 1 & is not bigger than (the new) number of members
		// This also ensures the last member is not removed
		if (voteThreshold_ < 1 || voteThreshold_ > _membersHashArray.length - 1)
			revert InvalidThreshold();

		emit RemovedMember(_members[memberHash]);

		delete _members[memberHash];
		for (uint256 i = 0; i < _membersHashArray.length; i++) {
			if (_membersHashArray[i] == memberHash) {
				_membersHashArray[i] = _membersHashArray[_membersHashArray.length - 1];
				_membersHashArray.pop();
				break;
			}
		}

		// Update voteThreshold
		_voteThreshold = voteThreshold_;

		// ! consider a nonce or similar to prevent replies (if sigs are used)
	}

	/// ----------------------------------------------------------------------------------------
	///							VIEW FUNCTIONS
	/// ----------------------------------------------------------------------------------------

	function getVoteThreshold() public view returns (uint256) {
		return _voteThreshold;
	}

	function getMembers() public view returns (uint256[2][] memory members) {
		uint256 len = _membersHashArray.length;

		members = new uint256[2][](len);

		for (uint256 i; i < len; ) {
			Member memory _mem = _members[_membersHashArray[i]];
			members[i] = [_mem.x, _mem.y];

			// Length of member array can't exceed max uint256
			unchecked {
				++i;
			}
		}
	}

	/**
	 * @notice Checks if a member is part of the group
	 * @param memberHash Hash of the member's public key: keccak256(abi.encodePacked(member.x, member.y))
	 * @return 1 if member is part of the group, 0 otherwise
	 */
	function isMember(bytes32 memberHash) public view returns (uint256) {
		return _members[memberHash].x != 0 ? 1 : 0;
	}
}
