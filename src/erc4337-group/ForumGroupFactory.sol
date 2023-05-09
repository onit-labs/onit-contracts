// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {Safe, Enum} from "@safe/Safe.sol";

import {ForumGroup} from "./ForumGroup.sol";

/// @notice Factory to deploy Forum group.
contract ForumGroupFactory {
    /// ----------------------------------------------------------------------------------------
    /// Errors and Events
    /// ----------------------------------------------------------------------------------------

    event ForumGroupDeployed(address indexed forumGroup);

    error NullDeploy();

    /// ----------------------------------------------------------------------------------------
    /// Factory Storage
    /// ----------------------------------------------------------------------------------------

    // Template contract to use for new forum groups
    address public immutable forumGroupSingleton;

    // Entry point to use for new forum groups
    address public immutable entryPoint;

    // Template contract to use for new Gnosis safe proxies
    address public immutable gnosisSingleton;

    // Library to use for ERC1271 compatability
    address public immutable gnosisFallbackLibrary;

    // Address of deterministic deployment proxy, allowing address generation independent of deployer or nonce
    // https://github.com/Arachnid/deterministic-deployment-proxy
    address public constant DETERMINISTIC_DEPLOYMENT_PROXY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // Data sent to the deterministic deployment proxy to deploy a new group module
    bytes private _createForumGroupProxyData;

    // TODO Making these immutable would save gas, but can't yet be done with dynamic types
    bytes public authData;

    string public clientDataStart;

    string public clientDataEnd;

    /// ----------------------------------------------------------------------------------------
    /// Constructor
    /// ----------------------------------------------------------------------------------------

    constructor(
        address payable _forumGroupSingleton,
        address _entryPoint,
        address _gnosisSingleton,
        address _gnosisFallbackLibrary,
        bytes memory _authData,
        string memory _clientDataStart,
        string memory _clientDataEnd
    ) {
        forumGroupSingleton = _forumGroupSingleton;
        entryPoint = _entryPoint;
        gnosisSingleton = _gnosisSingleton;
        gnosisFallbackLibrary = _gnosisFallbackLibrary;
        authData = _authData;
        clientDataStart = _clientDataStart;
        clientDataEnd = _clientDataEnd;

        // Data sent to the deterministic deployment proxy to deploy a new forum group
        _createForumGroupProxyData = abi.encodePacked(
            // constructor
            bytes10(0x3d602d80600a3d3981f3),
            // proxy code
            bytes10(0x363d3d373d3d3d363d73),
            _forumGroupSingleton,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
    }

    /// ----------------------------------------------------------------------------------------
    /// Factory Logic
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Deploys a new Forum group which manages a safe account
     * @param _name Name of the forum group
     * @param _members Array of key pairs for initial members on the group
     * @return forumGroup The deployed forum group
     * @dev Returns an existing account address so that entryPoint.getSenderAddress() works even after account creation
     */
    function createForumGroup(string calldata _name, uint256 _voteThreshold, uint256[2][] calldata _members)
        external
        payable
        virtual
        returns (address forumGroup)
    {
        // ! Improve this salt - should be safely unique, and easily reusuable across chain
        // ! Should also prevent any frontrunning to deploy to this address by anyone else
        bytes32 accountSalt = keccak256(abi.encodePacked(_name));

        address addr = getAddress(accountSalt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return payable(addr);
        }

        // Deploy module determinstically based on the salt (for now a hash of _name)
        (bool successCreate, bytes memory responseCreate) =
            DETERMINISTIC_DEPLOYMENT_PROXY.call{value: 0}(abi.encodePacked(accountSalt, _createForumGroupProxyData));

        // Convert response to address to be returned
        forumGroup = address(uint160(bytes20(responseCreate)));

        // If not successful, revert
        if (!successCreate || forumGroup == address(0)) revert NullDeploy();

        ForumGroup(payable(forumGroup)).initalize(
            entryPoint, gnosisFallbackLibrary, _voteThreshold, _members, authData, clientDataStart, clientDataEnd
        );

        emit ForumGroupDeployed(forumGroup);

        return forumGroup;
    }

    /// ----------------------------------------------------------------------------------------
    /// Factory Internal
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Get the address of an account that would be returned by createAccount()
     * @dev Salt should be keccak256(abi.encode(_name))
     */
    function getAddress(bytes32 salt) public view returns (address clone) {
        return address(
            bytes20(
                keccak256(abi.encodePacked(bytes1(0xff), DETERMINISTIC_DEPLOYMENT_PROXY, salt, keccak256(_createForumGroupProxyData)))
                    << 96
            )
        );
    }
}
