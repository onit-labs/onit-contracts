// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

import {IForumShareManager} from "../interfaces/IForumShareManager.sol";

/**
 * @dev TESTING ONLY - mints group token for members
 */
contract TestShareManager {
    function mintShares(address group, address to, uint256 id, uint256 amount)
        external
        payable
    {
        IForumShareManager(group).mintShares(to, id, amount);
    }

    function burnShares(address group, address from, uint256 id, uint256 amount)
        external
        payable
    {
        IForumShareManager(group).burnShares(from, id, amount);
    }
}
