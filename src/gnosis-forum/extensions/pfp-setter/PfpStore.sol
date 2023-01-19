// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {ERC1155} from '@solbase/src/tokens/ERC1155/ERC1155.sol';

import {Owned} from '@utils/Owned.sol'; // Consider upgrade to owned without conflicting Unauthorized error

import {IPfpAccessControl} from '@interfaces/IPfpAccessControl.sol';

contract PfpStore is ERC1155, Owned {
	/// ----------------------------------------------------------------------------------------
	/// EVENTS
	/// ----------------------------------------------------------------------------------------

	event PfpSet(address indexed dao, uint256 tokenId);

	event TokenAdded(uint256 tokenId, address manager);

	event TokenUpdated(uint256 tokenId, address manager, address accessControl, string uri);

	/// ----------------------------------------------------------------------------------------
	/// ERRORS
	/// ----------------------------------------------------------------------------------------

	error TokenMissing();

	error RestrictionSet();

	/// ----------------------------------------------------------------------------------------
	/// PFP STORAGE
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice The details of a token
	 * @param manager The manager of the token (can set the uri and access control)
	 * @param accessControl The address of the access control contract (mint restrictions etc)
	 * @param tokenUri The uri of the token
	 */
	struct TokenDetails {
		address manager;
		address accessControl;
		string tokenUri;
	}

	uint256 public tokenCount;

	// Manager allowed to create tokens
	mapping(address => uint256) public approvedManagers;

	// The details of each token
	mapping(uint256 => TokenDetails) public tokenDetails;

	/// ----------------------------------------------------------------------------------------
	/// CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	constructor(address deployer) Owned(deployer) ERC1155() {
		// Set the deployer as the manager of the first token, then restrict it from use to avoid tokenId = 0
		approvedManagers[deployer] = tokenCount;
		// From here first useable tokenId = 1
		emit TokenAdded(tokenCount++, deployer);
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Sets the manager for a token
	 * @param manager The address of the manager
	 */
	function setManager(address manager) external onlyOwner {
		approvedManagers[manager] = tokenCount;

		emit TokenAdded(tokenCount++, manager);
	}

	/// ----------------------------------------------------------------------------------------
	/// Manager Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Sets the access control for a token
	 * @param tokenId The id of the token
	 * @param accessControl The address of the access control contract
	 * @dev consider packing into abi encoded args
	 */
	function setTokenDetails(
		uint256 tokenId,
		address manager,
		address accessControl,
		string calldata tokenUri
	) external {
		if (!(msg.sender == tokenDetails[tokenId].manager)) revert Unauthorized();

		if (manager != address(0)) tokenDetails[tokenId].manager = manager;
		if (accessControl != address(0)) tokenDetails[tokenId].accessControl = accessControl;
		if (bytes(tokenUri).length > 2) tokenDetails[tokenId].tokenUri = tokenUri;

		emit TokenUpdated(tokenId, manager, accessControl, tokenUri);
	}

	/// ----------------------------------------------------------------------------------------
	/// ERC1155 Interface
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Returns the uri for a token
	 * @param id The id of the token
	 * @return The uri for the token
	 */
	function uri(uint256 id) public view override returns (string memory) {
		return tokenDetails[id].tokenUri;
	}

	/// ----------------------------------------------------------------------------------------
	/// PfP Logic
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice mints a token
	 * @param tokenId The id of the token
	 * @param to The address to mint to
	 * @param amount The amount to mint
	 * @param data The data to pass to the receiver
	 */
	function mint(uint256 tokenId, address to, uint256 amount, bytes calldata data) external {
		if (tokenId > tokenCount) revert TokenMissing();

		if (tokenDetails[tokenId].accessControl != address(0))
			if (
				!IPfpAccessControl(tokenDetails[tokenId].accessControl).mintRestriction(
					to,
					tokenId,
					amount,
					data
				)
			) revert RestrictionSet();

		_mint(to, tokenId, amount, data);
	}

	/**
	 * @notice burns a token
	 * @param tokenId The id of the token
	 * @param from The address to burn from
	 * @param amount The amount to burn
	 */
	function burn(uint256 tokenId, address from, uint256 amount) external {
		if (tokenId > tokenCount) revert TokenMissing();

		if (msg.sender != from) revert Unauthorized();

		if (tokenDetails[tokenId].accessControl != address(0))
			if (
				!IPfpAccessControl(tokenDetails[tokenId].accessControl).burnRestriction(
					from,
					tokenId,
					amount
				)
			) revert RestrictionSet();

		_burn(from, tokenId, amount);
	}

	/**
	 * @notice transfers a token
	 * @param id The id of the token
	 * @param from The address to transfer from
	 * @param to The address to transfer to
	 * @param amount The amount to transfer
	 * @param data The data to pass to the receiver
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) public override {
		if (tokenDetails[id].accessControl != address(0))
			if (
				!IPfpAccessControl(tokenDetails[id].accessControl).safeTransferFromRestriction(
					from,
					to,
					id,
					amount,
					data
				)
			) revert RestrictionSet();

		safeTransferFrom(from, to, id, amount, data);
	}
}
