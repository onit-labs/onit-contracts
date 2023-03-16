// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import '@gnosis/common/SelfAuthorized.sol';

/// @title MemberManager - Manages a set of members and a vThreshold to perform actions.
/// @author Forum (Modified from Safe OwnerManager by Stefan George - <stefan@gnosis.pm> & Richard Meissner - <richard@gnosis.pm>)
contract MemberManager is SelfAuthorized {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event AddedMember(Member member);
	event RemovedMember(Member member);
	event ChangedVThreshold(uint256 vThreshold);

	/// ----------------------------------------------------------------------------------------
	///							MEMBER MANAGER STORAGE
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Member struct
	 * @param x Address of member
	 * @param y Address of next member
	 * @dev x & y are the public key of the members P-256 passkey
	 */
	struct Member {
		uint256 x;
		uint256 y;
	}

	// We use the x value of a member as the head of the linked list
	// Initially, the head is set to 1
	Member internal SENTINEL = Member({x: 1, y: 1});

	mapping(uint256 => Member) internal members;

	uint256 internal memberCount;
	uint256 internal vThreshold;

	/// ----------------------------------------------------------------------------------------
	///							WRITE FUNCTIONS
	/// ----------------------------------------------------------------------------------------

	/// @dev Setup function sets initial storage of contract.
	/// @param _members List of Safe members.
	/// @param _vThreshold Number of required confirmations for a Safe transaction.
	function setupMembers(uint256[2][] memory _members, uint256 _vThreshold) internal {
		// Threshold can only be 0 at initialization.
		// Check ensures that setup function can only be called once.
		require(vThreshold == 0, 'MM200');
		// Validate that vThreshold is smaller than number of added members.
		require(_vThreshold <= _members.length, 'MM201');
		// There has to be at least one Safe member.
		require(_vThreshold >= 1, 'MM202');
		// Initializing Safe members.
		Member memory currentMember = SENTINEL;
		for (uint256 i = 0; i < _members.length; i++) {
			// Member address cannot be null.
			uint256[2] memory member = _members[i];
			// ! check this require
			require(
				member[0] != 0 &&
					member[1] != 0 &&
					member[0] != currentMember.x &&
					member[1] != currentMember.y,
				'MM203'
			);
			// No duplicate members allowed.
			require(members[member[0]].x == 0, 'MM204');
			members[currentMember.x] = Member({x: member[0], y: member[1]});
			currentMember = Member({x: member[0], y: member[1]});
		}
		members[currentMember.x] = SENTINEL;
		memberCount = _members.length;
		vThreshold = _vThreshold;
	}

	/// @dev Allows to add a new member to the Safe and update the vThreshold at the same time.
	///      This can only be done via a Safe transaction.
	/// @notice Adds the member `member` to the Safe and updates the vThreshold to `_vThreshold`.
	/// @param member New member address.
	/// @param _vThreshold New vThreshold.
	function addMemberWithThreshold(Member memory member, uint256 _vThreshold) public authorized {
		// Member address cannot be null, the sentinel or the Safe itself.
		// ! check this require
		require(
			member.x != 0 && member.y != 0 && member.x != SENTINEL.x && member.y != SENTINEL.y,
			'MM203'
		);
		// No duplicate members allowed.
		require(members[member.x].x == 0, 'MM204');
		members[member.x] = members[SENTINEL.x];
		members[SENTINEL.x] = member;
		memberCount++;
		emit AddedMember(member);
		// Change vThreshold if vThreshold was changed.
		if (vThreshold != _vThreshold) changeVThreshold(_vThreshold);
	}

	/// @dev Allows to remove an member from the Safe and update the vThreshold at the same time.
	///      This can only be done via a Safe transaction.
	/// @notice Removes the member `member` from the Safe and updates the vThreshold to `_vThreshold`.
	/// @param prevMember Member that pointed to the member to be removed in the linked list
	/// @param member Member address to be removed.
	/// @param _vThreshold New vThreshold.
	function removeMember(
		Member memory prevMember,
		Member memory member,
		uint256 _vThreshold
	) public authorized {
		// Only allow to remove an member, if vThreshold can still be reached.
		require(memberCount - 1 >= _vThreshold, 'MM201');
		// Validate member address and check that it corresponds to member index.
		require(
			member.x != 0 && member.y != 0 && member.x != SENTINEL.x && member.y != SENTINEL.y,
			'MM203'
		);
		require(
			members[prevMember.x].x == member.x && members[prevMember.x].y == member.y,
			'MM205'
		);
		members[prevMember.x] = members[member.x];
		// ! check this delete
		delete members[member.x];
		memberCount--;
		emit RemovedMember(member);
		// Change vThreshold if vThreshold was changed.
		if (vThreshold != _vThreshold) changeVThreshold(_vThreshold);
	}

	// /// @dev Allows to swap/replace an member from the Safe with another address.
	// ///      This can only be done via a Safe transaction.
	// /// @notice Replaces the member `oldMember` in the Safe with `newMember`.
	// /// @param prevMember Member that pointed to the member to be replaced in the linked list
	// /// @param oldMember Member address to be replaced.
	// /// @param newMember New member address.
	// function swapMember(
	// 	address prevMember,
	// 	address oldMember,
	// 	address newMember
	// ) public authorized {
	// 	// Member address cannot be null, the sentinel or the Safe itself.
	// 	require(
	// 		newMember != address(0) && newMember != SENTINEL_X && newMember != address(this),
	// 		'MM203'
	// 	);
	// 	// No duplicate members allowed.
	// 	require(members[newMember] == address(0), 'MM204');
	// 	// Validate oldMember address and check that it corresponds to member index.
	// 	require(oldMember != address(0) && oldMember != SENTINEL_X, 'MM203');
	// 	require(members[prevMember] == oldMember, 'MM205');
	// 	members[newMember] = members[oldMember];
	// 	members[prevMember] = newMember;
	// 	members[oldMember] = address(0);
	// 	emit RemovedMember(oldMember);
	// 	emit AddedMember(newMember);
	// }

	/// @dev Allows to update the number of required confirmations by Safe members.
	///      This can only be done via a Safe transaction.
	/// @notice Changes the vThreshold of the Safe to `_vThreshold`.
	/// @param _vThreshold New vThreshold.
	function changeVThreshold(uint256 _vThreshold) public authorized {
		// Validate that vThreshold is smaller than number of members.
		require(_vThreshold <= memberCount, 'MM201');
		// There has to be at least one Safe member.
		require(_vThreshold >= 1, 'MM202');
		vThreshold = _vThreshold;
		emit ChangedVThreshold(vThreshold);
	}

	/// ----------------------------------------------------------------------------------------
	///							VIEW FUNCTIONS
	/// ----------------------------------------------------------------------------------------

	function getVThreshold() public view returns (uint256) {
		return vThreshold;
	}

	function isMember(Member memory member) public view returns (bool) {
		// ! consider y check too
		return member.x != SENTINEL.x && members[member.x].x != 0;
	}

	/// @dev Returns array of members.
	/// @return array of Safe members.
	function getMembers() public view returns (uint256[2][] memory array) {
		array = new uint256[2][](memberCount);

		// populate return array
		uint256 index = 0;
		Member memory currentMember = members[SENTINEL.x];
		while (currentMember.x != SENTINEL.x) {
			array[index][0] = currentMember.x;
			array[index][1] = currentMember.y;
			currentMember = members[currentMember.x];
			index++;
		}
		return array;
	}
}
