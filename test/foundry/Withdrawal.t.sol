// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ForumGroup} from "../../src/Forum/ForumGroup.sol";
import {TestShareManager} from "../../src/Test/TestShareManager.sol";
import {ForumWithdrawal} from "../../src/Withdrawal/Withdrawal.sol";
import {CommissionManager} from
    "../../src/CommissionManager/CommissionManager.sol";

import {IForumGroupTypes} from "../../src/interfaces/IForumGroupTypes.sol";
import {IForumGroup} from "../../src/interfaces/IForumGroup.sol";

import {MockERC20} from "@solbase/test/utils/mocks/MockERC20.sol";
import {MockERC721} from "@solbase/test/utils/mocks/MockERC721.sol";

import "forge-std/Test.sol";
import "forge-std/StdCheats.sol";

contract WithdrawalTest is Test {
    ForumGroup public forumGroup;
    ForumWithdrawal public forumWithdrawal;
    TestShareManager public groupShareManager;
    CommissionManager public commissionManager;

    MockERC20 public mockErc20;
    MockERC20 public mockErc20_2;
    MockERC721 public mockErc721;

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
        forumWithdrawal = new ForumWithdrawal();
        commissionManager = new CommissionManager(alice);
        groupShareManager = new TestShareManager();

        mockErc20 = new MockERC20("MockERC20", "M20", 18);
        mockErc20_2 = new MockERC20("MockERC20_2", "M20_2", 18);
        mockErc721 = new MockERC721("MockERC721", "M721");

        // Initialise Forum Group
        setupForumGroup();

        // Mint group some assets
        vm.deal(address(forumGroup), 1 ether);
        mockErc20.mint(address(forumGroup), 1000);
        mockErc20_2.mint(address(forumGroup), 1000);
        mockErc721.mint(address(forumGroup), 1);

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

    /// @dev covers case of non member trying to withdraw from group
    function testCannotWithdrawMoreThanGroupTokenBalance() public {
        // Approve extension to send erc20
        vm.prank(address(forumGroup), address(forumGroup));
        mockErc20.approve(address(forumWithdrawal), 1000);

        // Check that the withdrawal fails if not enough balance
        vm.expectRevert(stdError.arithmeticError);
        vm.startPrank(alice, alice);
        forumGroup.callExtension(address(forumWithdrawal), 1001, "0x00");
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

    // A withdrawal of a non approved token via a custom proposal
    function testCallExtensionCustomWithdrawal() public {
        // Check init balances
        assertEq(mockErc20.balanceOf(address(forumGroup)), 1000);
        assertEq(mockErc20.balanceOf(alice), 0);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 1000);

        // Create payload for custom transfer of asset
        bytes memory payloadTransfer = abi.encodeWithSignature(
            "safeTransferFrom(address,address,uint256)",
            address(forumGroup),
            alice,
            1
        );

        // Create payload for processing the withdrawal
        bytes memory payloadBurn =
            abi.encodeWithSignature("burnGroupShares(address,uint256)", alice, 100);

        bytes[] memory payloads = new bytes[](2);
        payloads[0] = payloadTransfer;
        payloads[1] = payloadBurn;

        address[] memory addresses = new address[](2);
        addresses[0] = address(mockErc721);
        addresses[1] = address(forumWithdrawal);

        // Create custom withdrawal
        vm.prank(alice, alice);
        forumWithdrawal.submitWithdrawlProposal(
            IForumGroup(address(forumGroup)),
            addresses,
            new uint256[](2),
            payloads,
            100
        );

        // Sign the proposal number 1 as alice and process
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                forumGroup.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(forumGroup.PROPOSAL_HASH(), 1))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, digest);
        IForumGroupTypes.Signature[] memory signatures =
            new IForumGroupTypes.Signature[](1);
        signatures[0] = IForumGroupTypes.Signature(v, r, s);
        forumGroup.processProposal(1, signatures);

        // Check balances after erc721 withdrawal
        // assertEq(mockErc20.balanceOf(address(forumGroup)), 900);
        assertEq(mockErc721.balanceOf(alice), 1);
        assertEq(forumGroup.balanceOf(alice, TOKEN), 900);
    }
}
