// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @dev Renamed Unauthorized to NotOwner to prevent conflicts with other imports (ERC721 etc)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error NotOwner();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert NotOwner();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}
