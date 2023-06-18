// SPDX-License-Identifier: NONE
pragma solidity ^0.8.19;

import "./individual/ForumAccount.setup.t.sol";

import {ForumQrcodeNft} from "../src/nfts/ForumQrcodeNft.sol";

contract ForumQrcodeNftTest is ForumAccountTestSetup {
    ForumQrcodeNft public qrcodeNft;

    function setUp() public override {
        super.setUp();
        qrcodeNft = new ForumQrcodeNft(address(this), "Forum Qrcode Nft", "FORUM");
    }

    function test_mintQrCode() public {
        uint256 tokenId = getUintFromAddress(forumAccountAddress);

        vm.prank(forumAccountAddress);
        // Inputs here don't actually matter
        qrcodeNft.mintQrcode();

        assertEq(qrcodeNft.ownerOf(tokenId), forumAccountAddress);
        assertEq(qrcodeNft.balanceOf(forumAccountAddress), 1);
    }

    function test_mint() public {
        uint256 tokenId = getUintFromAddress(forumAccountAddress);

        vm.prank(forumAccountAddress);
        // Inputs here don't actually matter
        qrcodeNft.mint(address(this), 1);

        assertEq(qrcodeNft.ownerOf(tokenId), forumAccountAddress);
        assertEq(qrcodeNft.balanceOf(forumAccountAddress), 1);
    }

    function getUintFromAddress(address _addr) public pure returns (uint256) {
        return uint256(uint160(_addr));
    }
}
