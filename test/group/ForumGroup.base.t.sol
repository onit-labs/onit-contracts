// SPDX-License-Identifier: GPL-3.0-or-latersol
pragma solidity ^0.8.15;

import "../config/ERC4337TestConfig.t.sol";

import {MemberManager} from "@utils/MemberManager.sol"; // improve this import, try to take from ForumGroup

/**
 * TODO
 * - Improve salt for group deployment. Should be more restrictive to prevent frontrunning, and should work cross chain
 */

/**
 * @notice This contract contains some variables and functions used to test the ForumGroup contract
 * 			It is inherited by each ForumGroup test file
 */
contract ForumGroupTestBase is ERC4337TestConfig {
    ForumGroup internal forumGroup;

    address internal forumGroupAddress;

    bytes internal basicTransferCalldata;

    string internal constant GROUP_NAME_1 = "test";
    string internal constant GROUP_NAME_2 = "test2";

    /// -----------------------------------------------------------------------
    /// HELPERS
    /// -----------------------------------------------------------------------

    /**
     * @dev Returns the address which a public key will deploy to based of the individual account factory
     */
    function publicKeyAddress(uint256[2] memory publicKey_) public view returns (address) {
        return address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        bytes1(0xff),
                        0x4e59b44847b379578588920cA78FbF26c0B4956C,
                        keccak256(abi.encodePacked(publicKey_[0], publicKey_[1])),
                        keccak256(
                            abi.encodePacked(
                                // constructor
                                bytes10(0x3d602d80600a3d3981f3),
                                // proxy code
                                bytes10(0x363d3d373d3d3d363d73),
                                address(forumAccountSingleton),
                                bytes15(0x5af43d82803e903d91602b57fd5bf3)
                            )
                        )
                    )
                ) << 96
            )
        );
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    receive() external payable {}
}
