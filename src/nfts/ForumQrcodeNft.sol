// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {ERC721} from "@solbase/tokens/ERC721/ERC721.sol";
import {LibString} from "@solbase/utils/LibString.sol";

import {Owned} from "@utils/Owned.sol";

/// @notice ForumQrcodeNft is a simple ERC721 NFT contract for forum QR codes.
/// @author Forum (https://github.com/forumdaos/forum-contracts)

contract ForumQrcodeNft is ERC721, Owned {
    /// -----------------------------------------------------------------------
    /// ForumQrcodeNft Storage
    /// -----------------------------------------------------------------------

    error InvalidMinterAddress();

    // Read only storage bucket for QR codes
    string public baseUri;

    // Mapping of addresses allowed to mint for other people
    mapping(address => uint256) public allowedMinters;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner, string memory _name, string memory _symbol) Owned(_owner) ERC721(_name, _symbol) {}

    /// -----------------------------------------------------------------------
    /// Owner Functions
    /// -----------------------------------------------------------------------

    /// @notice Sets the base URI for the NFT.
    /// @param _baseUri The base URI to set.
    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    /// @notice Adds addresses allowed to mint NFTs for others.
    /// @param _allowedAddress The address to add.
    function toggleAllowedMinterAddress(address _allowedAddress, uint256 _setting) external onlyOwner {
        allowedMinters[_allowedAddress] = _setting;
    }

    /// -----------------------------------------------------------------------
    /// Minting
    /// -----------------------------------------------------------------------

    /// @notice Custom mint function for allowed minters
    /// @dev Lets Forum mint NFTs for accounts
    function mintQrcode(address _to) external payable {
        if (allowedMinters[msg.sender] != 1) revert InvalidMinterAddress();

        // We use address as token id to limit minting to one per address
        // and also to make linking the token uri easier
        _safeMint(_to, uint160(_to));
    }

    /// -----------------------------------------------------------------------
    /// Metadata
    /// -----------------------------------------------------------------------

    /// @notice Returns the URI for a given NFT.
    /// @param _id The ID of the NFT to return the URI for.
    /// @return The URI for the given NFT.
    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (_ownerOf[_id] == address(0)) revert NotMinted();

        return string(abi.encodePacked(baseUri, LibString.toString(_id), ".txt"));
    }
}
