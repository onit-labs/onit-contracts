// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/// @notice Forum group share manager interface
interface IForumShareManager {
    function mintShares(address to, uint256 amount) external payable;

    function burnShares(address from, uint256 amount) external payable;
}
