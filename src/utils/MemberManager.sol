// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@safe/common/SelfAuthorized.sol";

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
     * @param y Public key of member
     * @dev x & y are the public key of the members P-256 passkey
     */
    struct Member {
        uint256 x;
        uint256 y;
    }

    // Used to calcualte the address of the individual ERC-4337 account which members will have when deployed
    bytes32 immutable _accountCreationProxyData;

    // Number of required signatures for a Safe transaction.
    uint256 internal _voteThreshold;

    // Storing all members to index the mapping
    address[] internal _membersAddressArray;

    // Address is calculated from the public key of the member
    // The address may not yet be deployed
    mapping(address => Member) internal _members;

    /// ----------------------------------------------------------------------------------------
    ///							CONSTRUCTOR
    /// ----------------------------------------------------------------------------------------

    /// @notice Constructor sets the accountCreationProxyData
    /// @param singletonAccount_ Singleton from individual account factory
    constructor(address singletonAccount_) {
        _accountCreationProxyData = keccak256(
            abi.encodePacked(
                // constructor
                bytes10(0x3d602d80600a3d3981f3),
                // proxy code
                bytes10(0x363d3d373d3d3d363d73),
                singletonAccount_,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            )
        );
    }

    /// ----------------------------------------------------------------------------------------
    ///							MEMBER WRITE FUNCTIONS
    /// ----------------------------------------------------------------------------------------

    // ! consider visibility and access control
    /// @notice Changes the voteThreshold of the Safe to `voteThreshold`.
    /// @param voteThreshold New voteThreshold.
    function changeVoteThreshold(uint256 voteThreshold) public authorized {
        // Validate that voteThreshold is not bigger than number of members & is at least 1
        if (voteThreshold < 1 || voteThreshold > _membersAddressArray.length) revert InvalidThreshold();

        _voteThreshold = voteThreshold;
        emit ChangedVoteThreshold(_voteThreshold);
    }

    /// @notice Adds a member to the Safe.
    /// @param member Member to add.
    /// @param voteThreshold_ New voteThreshold.
    function addMemberWithThreshold(Member memory member, uint256 voteThreshold_) public authorized {
        address memberAddress = publicKeyAddress(member);
        if (_members[memberAddress].x != 0) revert MemberExists();

        // Validate that voteThreshold is at least 1 & is not bigger than (the new) number of members
        if (voteThreshold_ < 1 || voteThreshold_ > _membersAddressArray.length + 1) revert InvalidThreshold();

        _members[memberAddress] = member;
        _membersAddressArray.push(memberAddress);

        // Update voteThreshold
        _voteThreshold = voteThreshold_;

        // ! consider a nonce or similar to prevent replies (if sigs are used)
        emit AddedMember(member);
    }

    // ! improve handling of member array
    /// @notice Removes a member from the Safe & updates threshold.
    /// @param memberAddress Hash of the member's public key.
    /// @param voteThreshold_ New voteThreshold.
    function removeMemberWithThreshold(address memberAddress, uint256 voteThreshold_) public authorized {
        if (_members[memberAddress].x == 0) revert CannotRemoveMember();

        // Validate that voteThreshold is at least 1 & is not bigger than (the new) number of members
        // This also ensures the last member is not removed
        if (voteThreshold_ < 1 || voteThreshold_ > _membersAddressArray.length - 1) revert InvalidThreshold();

        emit RemovedMember(_members[memberAddress]);

        delete _members[memberAddress];
        for (uint256 i = 0; i < _membersAddressArray.length; i++) {
            if (_membersAddressArray[i] == memberAddress) {
                _membersAddressArray[i] = _membersAddressArray[_membersAddressArray.length - 1];
                _membersAddressArray.pop();
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
        uint256 len = _membersAddressArray.length;

        members = new uint256[2][](len);

        for (uint256 i; i < len;) {
            Member memory _mem = _members[_membersAddressArray[i]];
            members[i] = [_mem.x, _mem.y];

            // Length of member array can't exceed max uint256
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Checks if a member is part of the group
     * @param memberAddress Address from publicKeyAddress based on public key
     * @return 1 if member is part of the group, 0 otherwise
     */
    function isMember(address memberAddress) public view returns (uint256) {
        return _members[memberAddress].x != 0 ? 1 : 0;
    }

    /**
     * @dev Returns the address which a public key will deploy to based of the individual account factory
     * ! Find a more efficient way to calculate the address
     */
    function publicKeyAddress(Member memory pk) public view returns (address) {
        return address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xff),
                        0x4e59b44847b379578588920cA78FbF26c0B4956C,
                        keccak256(abi.encodePacked(pk.x, pk.y)),
                        _accountCreationProxyData
                    )
                ) << 96
            )
        );
    }
}
