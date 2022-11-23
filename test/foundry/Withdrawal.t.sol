// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from "../../src/Forum/ForumGroup.sol";
import {TestShareManager} from "../../src/Test/TestShareManager.sol";
import {ForumWithdrawal} from "../../src/Withdrawal/ForumWithdrawal.sol";
import {WithdrawalTransferManager} from
    "../../src/Withdrawal/WithdrawalTransferManager.sol";
import {CommissionManager} from
    "../../src/CommissionManager/CommissionManager.sol";

import {IForumGroupTypes} from "../../src/interfaces/IForumGroupTypes.sol";
import {IForumGroup} from "../../src/interfaces/IForumGroup.sol";

import {MockERC20} from "@solbase/test/utils/mocks/MockERC20.sol";
import {MockERC721} from "@solbase/test/utils/mocks/MockERC721.sol";
import {MockERC1155} from "@solbase/test/utils/mocks/MockERC1155.sol";

import "forge-std/Test.sol";
import "forge-std/StdCheats.sol";

contract WithdrawalTest is Test {
    ForumGroup public forumGroup;
    ForumWithdrawal public forumWithdrawal;
    WithdrawalTransferManager public withdrawalTransferManager;
    TestShareManager public groupShareManager;
    CommissionManager public commissionManager;

    MockERC20 public mockErc20;
    MockERC20 public mockErc20_2;
    MockERC721 public mockErc721;
    MockERC1155 public mockErc1155;

    address internal alice;
    uint256 internal alicePk;

    address[] internal tokens;

    uint256 internal constant MEMBERSHIP = 0;
    uint256 internal constant TOKEN = 1;

    uint256 internal WITHDRAWAL_START = block.timestamp;

    /// -----------------------------------------------------------------------
    /// Setup
    /// -----------------------------------------------------------------------

    function setUp() public {
        (alice, alicePk) = makeAddrAndKey("alice");

        // Contracts used in tests
        forumGroup = new ForumGroup();
        withdrawalTransferManager = new WithdrawalTransferManager();
        forumWithdrawal =
            new ForumWithdrawal(address(withdrawalTransferManager));
        commissionManager = new CommissionManager(alice);
        groupShareManager = new TestShareManager();

        mockErc20 = new MockERC20("MockERC20", "M20", 18);
        mockErc20_2 = new MockERC20("MockERC20_2", "M20_2", 18);
        mockErc721 = new MockERC721("MockERC721", "M721");
        mockErc1155 = new MockERC1155();

        // Initialise Forum Group
        setupForumGroup();

        // Mint group some assets
        vm.deal(address(forumGroup), 1 ether);
        mockErc20.mint(address(forumGroup), 1000);
        mockErc20_2.mint(address(forumGroup), 1000);
        mockErc721.mint(address(forumGroup), 1);
        mockErc1155.mint(address(forumGroup), 1, 1, "");

        // Set mock ERC20 as a withdrawal token
        tokens.push(address(mockErc20));
        vm.prank(address(forumGroup), address(forumGroup));
        forumWithdrawal.setExtension(
            abi.encode(tokens, uint256(WITHDRAWAL_START))
        );

        // Turn off commission manager for these tests
        vm.prank(address(alice), address(alice));
        commissionManager.setBaseCommission(0);
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
        vm.prank(address(forumGroup), address(forumGroup));
        forumWithdrawal.setExtension(
            abi.encode(tokens, uint256(WITHDRAWAL_START))
        );

        // Check that the withdrawal token is set
        assertEq(
            forumWithdrawal.withdrawables(address(forumGroup), 0),
            address(mockErc20),
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
    }

    /// @dev Covers case of non member trying to withdraw from group
    /// @dev We do not need to check for withdrawing an excess of erc20, since it can't
    //       be done - a proportional amount is withdrawn based on what balance there is
    function testCannotWithdrawMoreThanGroupTokenBalance() public {
        // Approve extension to send erc20
        vm.prank(address(forumGroup), address(forumGroup));
        mockErc20.approve(address(forumWithdrawal), 1000);

        // Check that the withdrawal fails if not enough group balance
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(alice, alice);
        forumGroup.callExtension(address(forumWithdrawal), 1001, "0x00");

        // Check balances after failed attempt, all unchanged
        assertEq(mockErc20.balanceOf(address(forumGroup)), 1000);
        assertEq(mockErc20.balanceOf(alice), 0);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 1000);
    }

    function testAddTokenToWithdrawals() public {
        // Check current withdrawal token
        assertEq(
            forumWithdrawal.withdrawables(address(forumGroup), 0),
            address(mockErc20),
            "Withdrawal token not set"
        );

        // Add new token to withdrawals
        address[] memory newTokens = new address[](1);
        newTokens[0] = address(mockErc20_2);
        vm.prank(address(forumGroup), address(forumGroup));
        forumWithdrawal.addTokens(newTokens);

        // Check that the withdrawal token is set
        assertEq(
            forumWithdrawal.withdrawables(address(forumGroup), 1),
            address(mockErc20_2),
            "Withdrawal token not set"
        );
    }

    function testRemoveTokenFromWithdrawals() public {
        // Check current withdrawal token
        assertEq(
            forumWithdrawal.withdrawables(address(forumGroup), 0),
            address(mockErc20),
            "Withdrawal token not set"
        );

        // Remove token from withdrawals
        uint256[] memory removalTokens = new uint256[](1);
        removalTokens[0] = uint256(0);
        vm.prank(address(forumGroup), address(forumGroup));
        forumWithdrawal.removeTokens(removalTokens);

        // Check that the withdrawal token is set
        assert(
            forumWithdrawal.getWithdrawables(address(forumGroup)).length == 0
        );
    }

    function testCallExtensionBasicWithdrawal() public {
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
    }

    function testCallExtensionBasicMultipleWithdrawalTokens() public {
        // Check init balances
        assertEq(mockErc20.balanceOf(address(forumGroup)), 1000);
        assertEq(mockErc20_2.balanceOf(address(forumGroup)), 1000);
        assertEq(mockErc20.balanceOf(alice), 0);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 1000);

        // Add new token to withdrawals
        address[] memory newTokens = new address[](1);
        newTokens[0] = address(mockErc20_2);
        vm.prank(address(forumGroup), address(forumGroup));
        forumWithdrawal.addTokens(newTokens);

        // Approve both tokens
        vm.prank(address(forumGroup), address(forumGroup));
        mockErc20.approve(address(forumWithdrawal), 1000);
        vm.prank(address(forumGroup), address(forumGroup));
        mockErc20_2.approve(address(forumWithdrawal), 1000);

        vm.prank(alice, alice);
        forumGroup.callExtension(address(forumWithdrawal), 100, "0x00");

        // Check balances after erc20 withdrawal
        assertEq(mockErc20.balanceOf(address(forumGroup)), 900);
        assertEq(mockErc20_2.balanceOf(address(forumGroup)), 900);
        assertEq(mockErc20.balanceOf(alice), 100);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 900);
    }

    /// -----------------------------------------------------------------------
    /// Custom Withdrawal
    /// -----------------------------------------------------------------------

    // A withdrawal of a non approved token via a custom proposal
    function testSubmitCustomWithdrawal() public {
        // Set one of each type ot token to test
        address[] memory accounts = new address[](3);
        accounts[0] = address(mockErc721);
        accounts[1] = address(mockErc1155);
        accounts[2] = address(mockErc20);

        // SOme amounts of each token to test
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = uint256(1);
        amounts[1] = uint256(1);
        amounts[2] = uint256(100);

        // Create custom withdrawal
        vm.prank(alice, alice);
        forumWithdrawal.submitWithdrawlProposal(
            IForumGroup(address(forumGroup)), accounts, amounts, 100
        );

        (
            address[] memory withdrawalAssets,
            uint256[] memory withdrawalAmounts,
            uint256 amountToBurn
        ) = forumWithdrawal.getCustomWithdrawals(address(forumGroup), alice);

        assertEq(withdrawalAssets, accounts);
        assertEq(withdrawalAmounts, amounts);
        assertEq(amountToBurn, 100);
    }

    function testCannotWithdrawMoreThanErc20Balance() public {
        address[] memory accounts = new address[](1);
        accounts[0] = address(mockErc20);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = uint256(1001);

        // Create custom withdrawal
        vm.prank(alice, alice);
        forumWithdrawal.submitWithdrawlProposal(
            IForumGroup(address(forumGroup)), accounts, amounts, 100
        );

        processProposal(1, forumGroup, false);

        // Check balances after fail, all unchanged
        assertEq(mockErc20.balanceOf(address(forumGroup)), 1000);
        assertEq(mockErc20.balanceOf(alice), 0);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 1000);
    }

    function testCannotWithdrawNonOwnedErc721() public {
        address[] memory accounts = new address[](1);
        accounts[0] = address(mockErc721);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = uint256(2);

        // Create custom withdrawal
        vm.prank(alice, alice);
        forumWithdrawal.submitWithdrawlProposal(
            IForumGroup(address(forumGroup)), accounts, amounts, 100
        );

        processProposal(1, forumGroup, false);

        // Check balances after erc721 withdrawal
        assertEq(mockErc721.balanceOf(address(forumGroup)), 1);
        assertEq(mockErc721.balanceOf(alice), 0);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 1000);
    }

    // A withdrawal of a non approved token via a custom proposal
    function testProcessCustomWithdrawal() public {
        // Check init balances
        assertEq(mockErc20.balanceOf(address(forumGroup)), 1000);
        assertEq(mockErc20.balanceOf(alice), 0);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 1000);

        address[] memory accounts = new address[](3);
        accounts[0] = address(mockErc721);
        accounts[1] = address(mockErc1155);
        accounts[2] = address(mockErc20);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = uint256(1);
        amounts[1] = uint256(1);
        amounts[2] = uint256(100);

        // Create custom withdrawal
        vm.prank(alice, alice);
        forumWithdrawal.submitWithdrawlProposal(
            IForumGroup(address(forumGroup)), accounts, amounts, 100
        );

        processProposal(1, forumGroup, true);

        // Check balances after erc721 withdrawal
        // assertEq(mockErc20.balanceOf(address(forumGroup)), 900);
        assertEq(mockErc721.balanceOf(alice), 1);
        assertEq(mockErc1155.balanceOf(alice, 1), 1);
        assertEq(mockErc20.balanceOf(alice), 100);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 900);
    }

    /// -----------------------------------------------------------------------
    /// Utils
    /// -----------------------------------------------------------------------

    /**
     * @notice Util to process a proposal with alice signing
     * @param proposal The id of the proposal to process
     * @param group The forum group to process the proposal for
     * @param expectPass Whether the prop should pass, or we check for a revert
     */
    function processProposal(
        uint256 proposal,
        ForumGroup group,
        bool expectPass
    )
        internal
    {
        // Sign the proposal number 1 as alice and process
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                group.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(group.PROPOSAL_HASH(), proposal))
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
        IForumGroupTypes.Signature[] memory signatures =
            new IForumGroupTypes.Signature[](1);
        signatures[0] = IForumGroupTypes.Signature(v, r, s);

        if (expectPass) {
            group.processProposal(proposal, signatures);
        } else {
            vm.expectRevert();
            group.processProposal(proposal, signatures);
        }
    }
}
