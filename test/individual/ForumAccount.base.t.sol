// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "../config/ERC4337TestConfig.t.sol";

import {Enum} from "../../src/erc4337-account/ForumAccount.sol";

/**
 * @notice This contract contains some variables and functions used to test the ForumAccount contract
 * 			It is inherited by each ForumAccount test file
 */
contract ForumAccountTestBase is ERC4337TestConfig {
    ForumAccount internal forumAccount;

    address payable internal forumAccountAddress;

    bytes internal basicTransferCalldata;

    /// -----------------------------------------------------------------------
    /// HELPERS
    /// -----------------------------------------------------------------------

    function accountSalt(uint256[2] memory owner) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner));
    }

    receive() external payable { // Allows this contract to receive ether
    }
}
