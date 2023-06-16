// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ERC721} from "@solbase/tokens/ERC721/ERC721.sol";
import {LibString} from "@solbase/utils/LibString.sol";

import {Owned} from "@utils/Owned.sol";

import {console} from "forge-std/console.sol";

/// @notice ForumQrcodeNft is a simple ERC721 NFT contract for forum QR codes.
/// @dev This contract is a simple ERC721 NFT contract for forum QR codes.
contract ForumQrcodeNft is ERC721, Owned {
    error InvalidId();

    // Read only storage bucket for QR codes
    string public baseUri = "https://pikwkrbfjjdwjbjijesv.supabase.co/storage/v1/object/public/qrcodes/";

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner, string memory _name, string memory _symbol) Owned(_owner) ERC721(_name, _symbol) {}

    /// -----------------------------------------------------------------------
    /// Owner Functions
    /// -----------------------------------------------------------------------

    /// @notice Sets the base URI for the NFT.
    /// @dev This function sets the base URI for the NFT.
    /// @param _baseUri The base URI to set.
    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    /// -----------------------------------------------------------------------
    /// Minting
    /// -----------------------------------------------------------------------

    /// @notice Mints a new NFT.
    /// @dev This function mints a new NFT.
    /// @param _id The ID of the NFT to mint.
    function mint(address to, uint256 _id) external payable {
        // Some checks on token ids

        // We use address as token id to limit minting to one per address
        // and also to make linking the token uri easier
        _safeMint(msg.sender, uint160(msg.sender));
    }

    /// -----------------------------------------------------------------------
    /// Burning
    /// -----------------------------------------------------------------------

    /// @notice Burns an existing NFT.
    /// @dev This function burns an existing NFT.
    /// @param _id The ID of the NFT to burn.
    function burn(uint256 _id) external payable {
        // check sender is owner

        _burn(_id);
    }

    /// -----------------------------------------------------------------------
    /// Metadata
    /// -----------------------------------------------------------------------

    /// @notice Returns the URI for a given NFT.
    /// @dev This function returns the URI for a given NFT.
    /// @param _id The ID of the NFT to return the URI for.
    /// @return The URI for the given NFT.
    function tokenURI(uint256 _id) public view override returns (string memory) {
        if (_ownerOf[_id] == address(0)) revert NotMinted();

        return string(abi.encodePacked(baseUri, LibString.toString(_id), ".txt"));
    }
}
