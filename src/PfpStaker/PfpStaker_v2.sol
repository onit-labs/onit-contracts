// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";
import {Owned} from "../utils/Owned.sol";
import {NFTreceiver} from "../utils/NFTreceiver.sol";

import {IPfpStaker} from "../interfaces/IPfpStaker.sol";

import {SVG} from "../libraries/SVG.sol";
import {JSON} from "../libraries/JSON.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

/**
 * @title PfpStaker
 * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
 */
contract PfpStaker_v2 is IPfpStaker, ReentrancyGuard, Owned, NFTreceiver {
    /// ----------------------------------------------------------------------------------------
    /// EVENTS
    /// ----------------------------------------------------------------------------------------

    event StakedNFT(address indexed dao, address NFTContract, uint256 tokenId);

    /// ----------------------------------------------------------------------------------------
    /// ERRORS
    /// ----------------------------------------------------------------------------------------

    error Unauthorised();

    error RestrictedNFT();

    error NotTokenHolder();

    /// ----------------------------------------------------------------------------------------
    /// PFP STORAGE
    /// ----------------------------------------------------------------------------------------

    address private immutable THIS_ADDRESS;

    address public shieldContract;
    address public forumFactory;

    bytes4 constant ERC721_METADATA = 0x5b5e139f;
    bytes4 constant ERC1155_METADATA = 0x0e89341c;

    /// When true, only certain contracts can be used as in app pfps
    bool public restrictedContracts = true;

    mapping(address => StakedPFP) public stakes;
    mapping(address => bool) public enabledPfpContracts;

    /// ----------------------------------------------------------------------------------------
    /// CONSTRUCTOR
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Allows groups to stake an NFT to use as their pfp - defaults to shield
     * @param deployer The address of the owner that is deploying the contract
     * @param shieldContract_ The address of the shield contract
     * @param forumFactory_ The address of the forum factory
     */
    constructor(
        address deployer,
        address shieldContract_,
        address forumFactory_
    ) Owned(deployer) {
        shieldContract = shieldContract_;

        forumFactory = forumFactory_;

        enabledPfpContracts[shieldContract_] = true;

        THIS_ADDRESS = address(this);
    }

    /// ----------------------------------------------------------------------------------------
    /// Owner Interface
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Set Forum Factory - this address can set stakers directly. This happens on multisig creation.
     * @param forumFactory_ Address of multisig factory
     */
    function setForumFactory(address forumFactory_) external onlyOwner {
        forumFactory = forumFactory_;
    }

    /**
     * @notice Update shieldContract
     * @param shieldContract_ Address of ShieldManager
     */
    function setShieldContract(address shieldContract_) external onlyOwner {
        shieldContract = shieldContract_;
        enabledPfpContracts[shieldContract_] = true;
    }

    /**
     * @notice Restrict the NFT collections that can be used as PFPs
     */
    function setRestrictedContracts() external onlyOwner {
        restrictedContracts = !restrictedContracts;
    }

    /**
     * @notice For adding allowed NFT collections
     * @param NFTContract Address of the contract to add to allowed list
     */
    function setEnabledContract(address NFTContract) external onlyOwner {
        enabledPfpContracts[NFTContract] = true;
    }

    /// ----------------------------------------------------------------------------------------
    /// External Interface
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Stake the initial shield minted during group creation
     * @param recipient Group that the shield is staked for
     * @param shieldId TokenId of shield
     */
    function stakeInitialShield(address recipient, uint256 shieldId) external {
        if (msg.sender != forumFactory) revert Unauthorised();

        stakes[recipient] = StakedPFP(shieldContract, shieldId);

        emit StakedNFT(recipient, shieldContract, shieldId);
    }

    /**
     * @notice Lets a group stake an NFT to use as their pfp
     * @param staker Address of the group doing the stake
     * @param NFTContract Address of the contract to add to allowed list
     * @param tokenId TokenId of shield
     */
    function stakeNFT(
        address staker,
        address NFTContract,
        uint256 tokenId
    ) external {
        if (restrictedContracts && !enabledPfpContracts[NFTContract])
            revert RestrictedNFT();

        if (msg.sender != staker) revert Unauthorised();

        // Check if NFTContract is ERC721
        if (IERC721(NFTContract).supportsInterface(ERC721_METADATA)) {
            if (IERC721(NFTContract).ownerOf(tokenId) != staker)
                revert NotTokenHolder();
            if (stakes[staker].NFTcontract != address(0)) unstakeNFT();

            // Transfer ERC721 from group to PFP
            IERC721(NFTContract).safeTransferFrom(
                staker,
                THIS_ADDRESS,
                tokenId
            );
            stakes[staker] = StakedPFP(NFTContract, tokenId);

            emit StakedNFT(staker, NFTContract, tokenId);
        } else {
            // Check if NFTContract is ERC1155
            if (IERC1155(NFTContract).supportsInterface(ERC1155_METADATA)) {
                if (IERC1155(NFTContract).balanceOf(staker, tokenId) == 0)
                    revert NotTokenHolder();

                if (stakes[staker].NFTcontract != address(0)) unstakeNFT();

                // Transfer ERC1155 from group to PFP
                IERC1155(NFTContract).safeTransferFrom(
                    staker,
                    THIS_ADDRESS,
                    tokenId,
                    1,
                    ""
                );
                stakes[staker] = StakedPFP(NFTContract, tokenId);

                emit StakedNFT(owner, NFTContract, tokenId);
            }
        }
    }

    /**
     * @notice Return URI for NFT depending on the type
     * @param staker Address of the contract to add to allowed list
     * @return nftURI The URI of the NFT
     */
    // Return URI for NFT depending on the type
    function getURI(address staker)
        external
        view
        returns (string memory nftURI)
    {
        // StakedPFP memory stake = stakes[staker];
        // if (IERC721(stake.NFTcontract).supportsInterface(ERC721_METADATA)) {
        // 	nftURI = IERC721Metadata(stake.NFTcontract).tokenURI(stake.tokenId);
        // } else {
        // 	if (IERC1155(stake.NFTcontract).supportsInterface(ERC1155_METADATA)) {
        // 		nftURI = IERC1155MetadataURI(stake.NFTcontract).uri(stake.tokenId);
        // 	}
        // }
        return _buildURI(1);
    }

    /**
     * @notice Return token staked by address
     * @return NFTContract
     * @return tokenId
     */
    function getStakedNFT()
        external
        view
        returns (address NFTContract, uint256 tokenId)
    {
        (NFTContract, tokenId) = (
            stakes[msg.sender].NFTcontract,
            stakes[msg.sender].tokenId
        );
    }

    /// ----------------------------------------------------------------------------------------
    /// Internal Interface
    /// ----------------------------------------------------------------------------------------

    function _buildURI(uint256 id) private pure returns (string memory) {
        return
            JSON._formattedMetadata(
                string.concat("Access #", SVG._uint2str(id)),
                "Group Token",
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" style="background:#191919">',
                    SVG._text(
                        string.concat(
                            SVG._prop("x", "20"),
                            SVG._prop("y", "40"),
                            SVG._prop("font-size", "22"),
                            SVG._prop("fill", "white")
                        ),
                        string.concat(SVG._cdata("Group X"), SVG._uint2str(id))
                    ),
                    SVG._rect(
                        string.concat(
                            SVG._prop("fill", "maroon"),
                            SVG._prop("x", "20"),
                            SVG._prop("y", "50"),
                            SVG._prop("width", SVG._uint2str(160)),
                            SVG._prop("height", SVG._uint2str(10))
                        ),
                        SVG.NULL
                    ),
                    SVG._image(
                        '<svg viewBox="0 0 220 100" xmlns="http://www.w3.org/2000/svg"><path d="M0 0h100v100H0z"/></svg>',
                        string.concat(
                            SVG._prop("x", "215"),
                            SVG._prop("y", "220"),
                            SVG._prop("width", "80")
                        )
                    ),
                    "</svg>"
                )
            );
    }

    function unstakeNFT() internal {
        if (
            IERC721(stakes[msg.sender].NFTcontract).supportsInterface(
                ERC721_METADATA
            )
        ) {
            IERC721(stakes[msg.sender].NFTcontract).safeTransferFrom(
                THIS_ADDRESS,
                msg.sender,
                stakes[msg.sender].tokenId
            );
        } else {
            if (
                IERC1155(stakes[msg.sender].NFTcontract).supportsInterface(
                    ERC1155_METADATA
                )
            ) {
                IERC1155(stakes[msg.sender].NFTcontract).safeTransferFrom(
                    THIS_ADDRESS,
                    msg.sender,
                    stakes[msg.sender].tokenId,
                    1,
                    ""
                );
            }
        }
    }
}
