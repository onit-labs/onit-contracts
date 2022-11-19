// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from "../../src/Forum/ForumGroup.sol";
import {TestShareManager} from "../../src/Test/TestShareManager.sol";
import {ForumWithdrawal} from "../../src/Withdrawal/Withdrawal.sol";
import {CommissionManager} from
    "../../src/CommissionManager/CommissionManager.sol";

import {MockERC20} from "@solbase/test/utils/mocks/MockERC20.sol";
import {MockERC1155} from "@solbase/test/utils/mocks/MockERC1155.sol";

import "forge-std/Test.sol";
import "forge-std/StdCheats.sol";

contract WithdrawalTest is Test {
    ForumGroup public forumGroup;
    ForumWithdrawal public forumWithdrawal;
    TestShareManager public groupShareManager;
    CommissionManager public commissionManager;

    MockERC20 public mockErc20;
    MockERC1155 public mockErc1155;

    address internal alice;

    address[] internal tokens;

    uint256 internal constant MEMBERSHIP = 0;
    uint256 internal constant TOKEN = 1;

    uint256 internal WITHDRAWAL_START = block.timestamp;

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public {
        alice = makeAddr("alice");

        // Contracts used in tests
        forumGroup = new ForumGroup();
        forumWithdrawal = new ForumWithdrawal();
        commissionManager = new CommissionManager(alice);
        groupShareManager = new TestShareManager();

        mockErc20 = new MockERC20("MockERC20", "M20", 18);
        mockErc1155 = new MockERC1155();

        // Initialise Forum Group
        setupForumGroup();

        // Mint group some assets
        mockErc20.mint(address(forumGroup), 1000);
        mockErc1155.mint(address(forumGroup), 0, 1000, "");

        // Set mock ERC20 as a withdrawal token
        tokens.push(address(mockErc20));
        vm.prank(address(forumGroup), address(forumGroup));
        forumWithdrawal.setExtension(
            abi.encode(tokens, uint256(WITHDRAWAL_START))
        );
    }

    function setupForumGroup() internal {
        address[] memory voters = new address[](1);
        voters[0] = alice;

        // Create initialExtensions array of correct length. 3 Forum set extensions + customExtensions
        address[] memory initialExtensions = new address[](5);

        // Set the extensions, pfpStaker (unused), commission manager, fundraise (unused), share manager, withdrawal
        (
            initialExtensions[0],
            initialExtensions[1],
            initialExtensions[2],
            initialExtensions[3],
            initialExtensions[4]
        ) = (
            address(0),
            address(commissionManager),
            address(0),
            address(groupShareManager),
            address(forumWithdrawal)
        );

        // Init the group
        forumGroup.init(
            "test",
            "T",
            voters,
            initialExtensions,
            [uint32(60), uint32(12), uint32(50), uint32(80)]
        );

        // Mint alice some group tokens
        groupShareManager.mintShares(address(forumGroup), alice, TOKEN, 1000);
    }

    /// -----------------------------------------------------------------------
    /// Test Logic
    /// -----------------------------------------------------------------------

    // some useful setup fns

    /// -----------------------------------------------------------------------
    /// Setup Extension
    /// -----------------------------------------------------------------------

    function testCannotSetEmptyWithdrawalsArray() public {
        vm.expectRevert(bytes4(keccak256("NullTokens()")));
        forumWithdrawal.setExtension(
            abi.encode(new address[](0), WITHDRAWAL_START)
        );
    }

    function testSetExtension() public {
        // Set mock ERC20 as a withdrawal token
        vm.startPrank(address(forumGroup), address(forumGroup));

        // Check that the withdrawal token is set
        assertEq(
            forumWithdrawal.withdrawables(address(forumGroup), 0),
            address(mockErc20),
            "Withdrawal token not set"
        );

        // Set mock ERC1155 as a withdrawal token - replacing the old tokens
        tokens.pop();
        tokens.push(address(mockErc1155));
        forumWithdrawal.setExtension(abi.encode(tokens, WITHDRAWAL_START));

        // Check that the withdrawal token is set
        assertEq(
            forumWithdrawal.withdrawables(address(forumGroup), 0),
            address(mockErc1155),
            "Withdrawal token not set"
        );
    }

    /// -----------------------------------------------------------------------
    /// Call Extension
    /// -----------------------------------------------------------------------

    function testCannotWithdrawBeforeStartTime() public {
        // Edit start time into future
        vm.startPrank(address(forumGroup), address(forumGroup));
        forumWithdrawal.setExtension(
            abi.encode(tokens, uint256(WITHDRAWAL_START + 1000))
        );

        // Approve extension to send erc20
        mockErc20.approve(address(forumWithdrawal), 1000);
        vm.stopPrank();

        // Check that the withdrawal fails before the deadline, but works after
        vm.startPrank(alice, alice);
        vm.expectRevert(bytes4(keccak256("NotStarted()")));
        forumGroup.callExtension(address(forumWithdrawal), 100, "0x00");
        skip(1001);
        forumGroup.callExtension(address(forumWithdrawal), 1, "0x00");

        rewind(1001);
    }

    function testCannotWithdrawMoreThanGroupTokenBalance() public {
        // Approve extension to send erc20
        vm.prank(address(forumGroup), address(forumGroup));
        mockErc20.approve(address(forumWithdrawal), 1000);

        // Check that the withdrawal fails if not enough balance
        vm.startPrank(alice, alice);
        vm.expectRevert(stdError.arithmeticError);
        forumGroup.callExtension(address(forumWithdrawal), 1001, "0x00");
    }

    function testCallExtensionBasic() public {
        assertTrue(true);

        // Check init balances
        assertEq(mockErc20.balanceOf(address(forumGroup)), 1000);
        assertEq(mockErc20.balanceOf(alice), 0);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 1000);

        // Test erc20 token already set in setUp()
        vm.prank(address(forumGroup), address(forumGroup));
        mockErc20.approve(address(forumWithdrawal), 1000);

        vm.prank(alice, alice);
        forumGroup.callExtension(address(forumWithdrawal), 100, "0x00");

        // Check balances after erc20 withdrawal
        assertEq(mockErc20.balanceOf(address(forumGroup)), 900);
        assertEq(mockErc20.balanceOf(alice), 100);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 900);

        // Test with erc1155 token
        // called by member calling the callExtension function on the group contract
        // only distributes a preset token
        // check balance of group, member, and that tokens have been burned
    }
}
