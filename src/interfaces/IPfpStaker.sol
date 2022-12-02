// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp
interface IPfpStaker {
	function stakeNft(address, uint256) external;

	function getUri(address, string calldata) external view returns (string memory nftURI);

	function getStakedNft(address) external view returns (uint256 tokenId);
}
