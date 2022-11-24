// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp
interface IPfpStaker {
	struct StakedPFP {
		address Nftcontract;
		uint256 tokenId;
	}

	function stakeNFT(address, address, uint256) external;

	function getURI(address, string calldata) external view returns (string memory nftURI);

	function getStakedNFT(address) external view returns (address NftContract, uint256 tokenId);
}
