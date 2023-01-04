// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import {OrderTypes} from "../../libraries/OrderTypes.sol";

import {IERC165} from "../../interfaces/IERC165.sol";

/**
 * @title JoepegsCrowdfundHandler
 * @notice Handles decoding of crowdfund payload for Joepegs Marketplace
 */
contract JoepegsCrowdfundHandler {
    /// ----------------------------------------------------------------------------------------
    ///							JoepegsCrowdfundHandler Storage
    /// ----------------------------------------------------------------------------------------

    error InvalidFunction();

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// bytes4 key is the function signature
    mapping(bytes4 => uint256) public enabledMethods;

    /// ----------------------------------------------------------------------------------------
    ///							Constructor
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Constructor
     * @param _enabledMethods Array of function signatures to enable
     */
    constructor(bytes4[] memory _enabledMethods) {
        // Set the functions that are enabled -> 1 for enabled
        for (uint256 i; i < _enabledMethods.length; i++) {
            enabledMethods[_enabledMethods[i]] = 1;
        }
    }

    /// ----------------------------------------------------------------------------------------
    ///							Public Interface
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Decides commission to charge based on the function being called.
     *     		 Since all on-chain joe functions decode a TakerOrder, we can do
     *     		 everything in handleCrowdfund.
     * @param crowdfundContract address of the crowdfund contract
     * @param assetContract address of the asset contract
     * @param forumGroup address of the forum group
     * @param tokenId tokenId of the NFT
     * @return payload to decode and extract commission info from
     */
    function handleCrowdfundExecution(
        address crowdfundContract,
        address assetContract,
        address forumGroup,
        uint256 tokenId,
        bytes calldata payload
    )
        external
        view
        returns (uint256, bytes memory)
    {
        // Extract function sig from payload as the first 4 bytes
        bytes4 functionSig = bytes4(payload[0:4]);

        // If enabled method, decode the payload, extract price, and form transferPayload
        if (enabledMethods[functionSig] == 1) {
            OrderTypes.TakerOrder memory takerOrder =
                abi.decode(payload[4:], (OrderTypes.TakerOrder));

            // Build a transfer payload depending on the asset type
            if (IERC165(assetContract).supportsInterface(INTERFACE_ID_ERC721)) {
                return (
                    takerOrder.price,
                    abi.encodeWithSignature(
                        "safeTransferFrom(address,address,uint256)",
                        crowdfundContract,
                        forumGroup,
                        tokenId
                        )
                );
            }
            if (IERC165(assetContract).supportsInterface(INTERFACE_ID_ERC1155))
            {
                return (
                    takerOrder.price,
                    abi.encodeWithSignature(
                        "safeTransferFrom(address,address,uint256,uint256,bytes)",
                        crowdfundContract,
                        forumGroup,
                        tokenId,
                        1,
                        ""
                        )
                );
            }
        }

        // If function is not listed, revert
        revert InvalidFunction();
    }
}
