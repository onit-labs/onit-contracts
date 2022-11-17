// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from "../../src/Forum/ForumGroup.sol";
import {CommissionManager} from
    "../../src/CommissionManager/CommissionManager.sol";

import "forge-std/Test.sol";
import "forge-std/StdCheats.sol";

contract WithdrawalTest is Test {
    ForumGroup forumGroup;
    CommissionManager commissionManager;

    address internal alice;

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public {
        alice = makeAddr("alice");

        // Contracts used in tests
        forumGroup = new ForumGroup();
        commissionManager = new CommissionManager(alice);

        // Initialise Forum Group
        setupForumGroup();
    }

    function setupForumGroup() internal {
        address[] memory voters = new address[](1);
        voters[0] = alice;

        // Create initialExtensions array of correct length. 3 Forum set extensions + customExtensions
        address[] memory initialExtensions = new address[](3);

        // Set the base Forum extensions
        (initialExtensions[0], initialExtensions[1], initialExtensions[2]) =
            (address(0), address(commissionManager), address(0));

        forumGroup.init(
            "test",
            "T",
            voters,
            initialExtensions,
            [uint32(60), uint32(12), uint32(50), uint32(80)]
        );
    }

    /// -----------------------------------------------------------------------
    /// Test Logic
    /// -----------------------------------------------------------------------

    // some useful setup fns

    /// -----------------------------------------------------------------------
    /// Setup Extension
    /// -----------------------------------------------------------------------

    function testCannotSetEmptyWithdrawalsArray() public {
        assertTrue(true);
    }

    function testSetExtension() public {
        assertTrue(true);
    }

    function testSetExtensionWithReplacement() public {
        assertTrue(true);
    }

    /// -----------------------------------------------------------------------
    /// Call Extension
    /// -----------------------------------------------------------------------

    function testCannotWithdrawBeforeStartTime() public {
        assertTrue(true);

        //
    }

    function testCallExtensionBasic() public {
        assertTrue(true);

        // called by member calling the callExtension function on the group contract
        // only distributes a preset token
        // check balance of group, member, and that tokens have been burned
    }
}
