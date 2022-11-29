// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ReentrancyGuard} from '../utils/ReentrancyGuard.sol';
import {NFTreceiver} from '../utils/NFTreceiver.sol';

import {IPfpStaker} from '../interfaces/IPfpStaker.sol';
import {Owned} from '../utils/Owned.sol';

import {SVG} from '../libraries/SVG.sol';
import {JSON} from '../libraries/JSON.sol';

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IERC721Metadata} from '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import {IERC1155} from '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import {IERC1155MetadataURI} from '@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol';

/**
 * @title PfpStaker
 * @notice Allows groups to stake an NFT to use as their pfp and generates token uri for group tokens
 */
contract PfpStaker is IPfpStaker, ReentrancyGuard, NFTreceiver, Owned {
	/// ----------------------------------------------------------------------------------------
	/// EVENTS
	/// ----------------------------------------------------------------------------------------

	event StakedNft(address indexed dao, address NftContract, uint256 tokenId);

	/// ----------------------------------------------------------------------------------------
	/// ERRORS
	/// ----------------------------------------------------------------------------------------

	error Unauthorised();

	error NotTokenHolder();

	/// ----------------------------------------------------------------------------------------
	/// PFP STORAGE
	/// ----------------------------------------------------------------------------------------

	address private immutable THIS_ADDRESS;

	bytes4 private constant ERC721_METADATA = 0x5b5e139f;
	bytes4 private constant ERC1155_METADATA = 0x0e89341c;

	mapping(address => StakedPFP) public stakes;

	/// ----------------------------------------------------------------------------------------
	/// CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
	 */
	constructor(address deployer) Owned(deployer) {
		THIS_ADDRESS = address(this);
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	// Add contract to mint 1155 tokens, let collections add to this

	/// ----------------------------------------------------------------------------------------
	/// External Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Lets a group stake an NFT to use as their pfp
	 * @param staker Address of the group doing the stake
	 * @param NftContract Address of the contract to add to allowed list
	 * @param tokenId TokenId of shield
	 */
	function stakeNFT(address staker, address NftContract, uint256 tokenId) external {
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
					if (IERC1155(NftContract).balanceOf(staker, tokenId) == 0)
						revert NotTokenHolder();

					if (stakes[staker].Nftcontract != address(0)) unstakeNFT();

					// Transfer ERC1155 from group to PFP
					IERC1155(NftContract).safeTransferFrom(staker, THIS_ADDRESS, tokenId, 1, '');
					stakes[staker] = StakedPFP(NftContract, tokenId);

					emit StakedNFT(staker, NftContract, tokenId);
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
	function getURI(
		address staker,
		string calldata groupName
	) external view returns (string memory) {
		StakedPFP memory stake = stakes[staker];

		string memory image;
		if (stake.Nftcontract == address(0)) {
			image = '<path fill-rule="evenodd" clip-rule="evenodd" d="M124.215 103.45c-3.719.034-6.707 3.074-6.673 6.79.003.286.023.568.06.845-7.708 6.251-13.137 14.89-15.413 24.574-2.3899 10.169-1.153 20.852 3.496 30.208 4.65 9.356 12.421 16.797 21.974 21.04 9.553 4.244 20.289 5.024 30.356 2.206-.823-1.972-1.166-3.147-1.498-5.342-8.822 2.47-18.23 1.786-26.602-1.933-8.372-3.719-15.182-10.24-19.257-18.438-4.074-8.199-5.158-17.561-3.063-26.473 1.944-8.271 6.513-15.673 12.997-21.115 1.076.704 2.365 1.108 3.747 1.095 3.719-.034 6.707-3.074 6.673-6.79-.034-3.717-3.077-6.702-6.797-6.667Zm.024 2.577c2.295-.021 4.172 1.821 4.193 4.113.021 2.293-1.822 4.169-4.117 4.19-2.295.021-4.172-1.821-4.193-4.113-.021-2.293 1.822-4.169 4.117-4.19ZM171.483 178.023l.321.404c.462.66.737 1.461.748 2.327.027 2.293-1.811 4.173-4.105 4.201-2.295.027-4.178-1.809-4.205-4.102-.028-2.292 1.81-4.173 4.105-4.201 1.242-.015 2.364.517 3.136 1.371Zm3.602 1.985c7.44-6.358 12.609-14.983 14.693-24.57 2.196-10.102.833-20.652-3.859-29.866-4.692-9.214-12.425-16.526-21.891-20.7-9.466-4.173-20.084-4.9524-30.059-2.205.887 2.025 1.228 3.191 1.475 5.348 8.742-2.407 18.047-1.725 26.343 1.933 8.295 3.657 15.072 10.065 19.183 18.14 4.112 8.074 5.307 17.32 3.382 26.173-1.764 8.112-6.048 15.438-12.21 20.949-1.093-.732-2.411-1.152-3.826-1.135-3.719.044-6.698 3.093-6.654 6.809.045 3.716 3.096 6.693 6.816 6.648 3.719-.044 6.698-3.093 6.653-6.809-.002-.242-.018-.48-.046-.715Z" fill="#fff"/><path d="M168.35 145.914c0 12.388-10.051 22.431-22.45 22.431s-22.451-10.043-22.451-22.431c0-12.388 10.052-22.431 22.451-22.431 12.399 0 22.45 10.043 22.45 22.431Zm-39.416 0c0 9.362 7.596 16.951 16.966 16.951 9.37 0 16.966-7.589 16.966-16.951s-7.596-16.951-16.966-16.951c-9.37 0-16.966 7.589-16.966 16.951Z" fill="#fff"/>';
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
	function getStakedNFT(
		address staker
	) external view returns (address NftContract, uint256 tokenId) {
		(NftContract, tokenId) = (stakes[staker].Nftcontract, stakes[staker].tokenId);
	}

	/// ----------------------------------------------------------------------------------------
	/// Internal Interface
	/// ----------------------------------------------------------------------------------------

	function _buildURI(
		string calldata groupName,
		string memory image
	) private pure returns (string memory) {
		return
			JSON._formattedMetadata(
				string.concat('Access #'),
				'Group Token',
				string.concat(
					'<svg width="300" height="300" fill="none" xmlns="http://www.w3.org/2000/svg"><filter id="filter" x="0" y="0" width="300" height="300" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="-80"/><feGaussianBlur stdDeviation="50"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0"/><feBlend in2="shape" result="effect1_innerShadow_2276_3624"/></filter><g filter="url(#filter)"><rect width="300" height="300" rx="11.078" fill="#37373D" fill-opacity=".5"/></g>',
					SVG._el(
						'g',
						string.concat(SVG._prop('id', 'background'), SVG._prop('filter', 'filter')),
						image
					),
					SVG._el(
						'use',
						string.concat(
							SVG._prop('x', '0'),
							SVG._prop('y', '0'),
							SVG._prop('href', '#background')
						),
						''
					),
					SVG._text(
						string.concat(
							SVG._prop('x', '20'),
							SVG._prop('y', '250'),
							SVG._prop('font-size', '22'),
							SVG._prop('fill', 'white')
						),
						SVG._cdata(groupName)
					),
					SVG._text(
						string.concat(
							SVG._prop('x', '20'),
							SVG._prop('y', '270'),
							SVG._prop('font-size', '12'),
							SVG._prop('fill', 'white')
						),
						SVG._cdata('Membership Pass')
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
