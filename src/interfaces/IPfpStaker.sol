// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

// Sets the token uri for group tokens
interface IPfpStaker {
	function stakeNft(address, uint256) external;

	function getUri(address, string calldata, uint256) external view returns (string memory nftURI);

	function getStakedNft(address) external view returns (uint256 tokenId);
}
