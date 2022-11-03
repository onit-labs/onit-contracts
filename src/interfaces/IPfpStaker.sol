// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// PFP allows groups to stake an NFT to use as their pfp - defaults to shield
interface IPfpStaker {
	struct StakedPFP {
		address NFTcontract;
		uint256 tokenId;
	}

	function stakeInitialShield(address, uint256) external;

	function stakeNFT(
		address,
		address,
		uint256
	) external;

	function getURI(address) external view returns (string memory nftURI);

	function getStakedNFT() external view returns (address NFTContract, uint256 tokenId);
}
