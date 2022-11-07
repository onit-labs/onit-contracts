// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';
import {Owned} from '../utils/Owned.sol';
import {NFTreceiver} from '../utils/NFTreceiver.sol';

import {IPfpStakerV2} from '../interfaces/IPfpStakerV2.sol';

import {SVG} from '../libraries/SVG.sol';
import {JSON} from '../libraries/JSON.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC1155MetadataURI} from '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';

/**
 * @title PfpStakerV2
 * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
 */
contract PfpStakerV2 is IPfpStakerV2, ReentrancyGuard, Owned, NFTreceiver {
	/// ----------------------------------------------------------------------------------------
	/// EVENTS
	/// ----------------------------------------------------------------------------------------

	event StakedNFT(address indexed dao, address NftContract, uint256 tokenId);

	/// ----------------------------------------------------------------------------------------
	/// ERRORS
	/// ----------------------------------------------------------------------------------------

	error Unauthorised();

	error NotTokenHolder();

	/// ----------------------------------------------------------------------------------------
	/// PFP STORAGE
	/// ----------------------------------------------------------------------------------------

	address private immutable THIS_ADDRESS;

	bytes4 constant ERC721_METADATA = 0x5b5e139f;
	bytes4 constant ERC1155_METADATA = 0x0e89341c;

	mapping(address => StakedPFP) public stakes;

	/// ----------------------------------------------------------------------------------------
	/// CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
	 * @param deployer The address of the owner that is deploying the contract
	 */
	constructor(address deployer) Owned(deployer) {
		THIS_ADDRESS = address(this);
	}

	/// ----------------------------------------------------------------------------------------
	/// External Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Lets a group stake an NFT to use as their pfp
	 * @param staker Address of the group doing the stake
	 * @param NftContract Address of the contract to add to allowed list
	 * @param tokenId TokenId of shield
	 */
	function stakeNFT(
		address staker,
		address NftContract,
		uint256 tokenId
	) external {
		if (msg.sender != staker) revert Unauthorised();

		if (NftContract == address(0)) {
			unstakeNFT();
		} else {
			// Check if NftContract is ERC721
			if (IERC721(NftContract).supportsInterface(ERC721_METADATA)) {
				if (IERC721(NftContract).ownerOf(tokenId) != staker) revert NotTokenHolder();
				if (stakes[staker].Nftcontract != address(0)) unstakeNFT();

				// Transfer ERC721 from group to PFP
				IERC721(NftContract).safeTransferFrom(staker, THIS_ADDRESS, tokenId);
				stakes[staker] = StakedPFP(NftContract, tokenId);

				emit StakedNFT(staker, NftContract, tokenId);
			} else {
				// Check if NftContract is ERC1155
				if (IERC1155(NftContract).supportsInterface(ERC1155_METADATA)) {
					if (IERC1155(NftContract).balanceOf(staker, tokenId) == 0) revert NotTokenHolder();

					if (stakes[staker].Nftcontract != address(0)) unstakeNFT();

					// Transfer ERC1155 from group to PFP
					IERC1155(NftContract).safeTransferFrom(staker, THIS_ADDRESS, tokenId, 1, '');
					stakes[staker] = StakedPFP(NftContract, tokenId);

					emit StakedNFT(owner, NftContract, tokenId);
				}
			}
		}
	}

	/**
	 * @notice Return URI for NFT depending on the type
	 * @param staker Address of the contract to add to allowed list
	 * @return nftURI The URI of the NFT
	 */
	// Return URI for NFT depending on the type
	function getURI(address staker, string calldata groupName) external view returns (string memory) {
		StakedPFP memory stake = stakes[staker];

		string memory image;
		if (stake.Nftcontract == address(0)) {
			image = '<svg viewBox="0 0 220 100" xmlns="http://www.w3.org/2000/svg"><path d="M0 0h100v100H0z"/></svg>';
		} else {
			// Check if NftContract is ERC721
			if (IERC721(stake.Nftcontract).supportsInterface(ERC721_METADATA)) {
				image = IERC721Metadata(stake.Nftcontract).tokenURI(stake.tokenId);
			} else {
				// Check if NftContract is ERC1155
				if (IERC1155(stake.Nftcontract).supportsInterface(ERC1155_METADATA)) {
					image = IERC1155MetadataURI(stake.Nftcontract).uri(stake.tokenId);
				}
			}
		}
		return _buildURI(groupName, image);
	}

	/**
	 * @notice Return token staked by address
	 * @return NftContract
	 * @return tokenId
	 */
	function getStakedNFT(address staker)
		external
		view
		returns (address NftContract, uint256 tokenId)
	{
		(NftContract, tokenId) = (stakes[staker].Nftcontract, stakes[staker].tokenId);
	}

	/// ----------------------------------------------------------------------------------------
	/// Internal Interface
	/// ----------------------------------------------------------------------------------------

	function _buildURI(string calldata groupName, string memory image)
		private
		pure
		returns (string memory)
	{
		return
			JSON._formattedMetadata(
				string.concat('Access #'),
				'Group Token',
				string.concat(
					'<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#191919">',
					SVG._text(
						string.concat(
							SVG._prop('x', '20'),
							SVG._prop('y', '40'),
							SVG._prop('font-size', '22'),
							SVG._prop('fill', 'white')
						),
						SVG._cdata(groupName)
					),
					SVG._rect(
						string.concat(
							SVG._prop('fill', 'maroon'),
							SVG._prop('x', '20'),
							SVG._prop('y', '50'),
							SVG._prop('width', SVG._uint2str(160)),
							SVG._prop('height', SVG._uint2str(10))
						),
						SVG.NULL
					),
					SVG._image(
						image,
						string.concat(SVG._prop('x', '215'), SVG._prop('y', '220'), SVG._prop('width', '80'))
					),
					'</svg>'
				)
			);
	}

	function unstakeNFT() internal {
		if (IERC721(stakes[msg.sender].Nftcontract).supportsInterface(ERC721_METADATA)) {
			IERC721(stakes[msg.sender].Nftcontract).safeTransferFrom(
				THIS_ADDRESS,
				msg.sender,
				stakes[msg.sender].tokenId
			);
		} else {
			if (IERC1155(stakes[msg.sender].Nftcontract).supportsInterface(ERC1155_METADATA)) {
				IERC1155(stakes[msg.sender].Nftcontract).safeTransferFrom(
					THIS_ADDRESS,
					msg.sender,
					stakes[msg.sender].tokenId,
					1,
					''
				);
			}
		}
	}
}
