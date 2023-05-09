// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable avoid-low-level-calls */

import {Safe, Enum} from "@safe/Safe.sol";

import {ForumAccount, IEntryPoint} from "./ForumAccount.sol";

/// @notice Factory to deploy an ERC4337 Account
/// @author ForumDAOs (https://forumdaos.com)
contract ForumAccountFactory {
    /// ----------------------------------------------------------------------------------------
    /// Errors and Events
    /// ----------------------------------------------------------------------------------------

    error NullDeploy();

    error AccountInitFailed();

    /// ----------------------------------------------------------------------------------------
    /// Factory Storage
    /// ----------------------------------------------------------------------------------------

    // Template contract to use for new individual ERC4337 accounts
    ForumAccount public immutable forumAccountSingleton;

    // Entry point used for ERC4337 accounts
    address public immutable entryPoint;

    // Fallback handler for Gnosis Safe
    address public immutable gnosisFallbackLibrary;

    // Address of deterministic deployment proxy, allowing address generation independent of deployer or nonce
    // https://github.com/Arachnid/deterministic-deployment-proxy
    address public constant DETERMINISTIC_DEPLOYMENT_PROXY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    bytes private _createProxyData;

    bytes32 private immutable _createProxyDataHash;

    string public clientDataStart;
    string public clientDataEnd;
    bytes public authData;

    /// ----------------------------------------------------------------------------------------
    /// Constructor
    /// ----------------------------------------------------------------------------------------

    constructor(
        ForumAccount _forumAccountSingleton,
        address _entryPoint,
        address _gnosisFallbackLibrary,
        bytes memory _authData,
        string memory _clientDataStart,
        string memory _clientDataEnd
    ) {
        forumAccountSingleton = _forumAccountSingleton;

        entryPoint = _entryPoint;

        gnosisFallbackLibrary = _gnosisFallbackLibrary;

        authData = _authData;

        clientDataStart = _clientDataStart;

        clientDataEnd = _clientDataEnd;

        // Data sent to the deterministic deployment proxy to deploy a new ERC4337 account
        _createProxyData = abi.encodePacked(
            // constructor
            bytes10(0x3d602d80600a3d3981f3),
            // proxy code
            bytes10(0x363d3d373d3d3d363d73),
            _forumAccountSingleton,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );

        // Hashed so we can save this as immutable to save gas calcualting address
        _createProxyDataHash = keccak256(_createProxyData);
    }

    /// ----------------------------------------------------------------------------------------
    /// Factory Logic
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Deploys a new ERC4337 account built on a Gnosis safe
     * @param owner Public key for secp256r1 signer
     * @return account The deployed account
     * @dev Returns an existing account address so that entryPoint.getSenderAddress() works even after account creation
     */
    function createForumAccount(uint256[2] calldata owner) external payable virtual returns (address payable account) {
        bytes32 accountSalt = keccak256(abi.encodePacked(owner));

        address addr = getAddress(accountSalt);
        uint256 codeSize = addr.code.length;
        if (codeSize > 0) {
            return payable(addr);
        }

        // Deploy the account determinstically based on the salt
        (bool successCreate, bytes memory responseCreate) =
            DETERMINISTIC_DEPLOYMENT_PROXY.call{value: 0}(abi.encodePacked(accountSalt, _createProxyData));

        // If successful, convert response to address to be returned
        account = payable(address(uint160(bytes20(responseCreate))));

        if (!successCreate || account == address(0)) revert NullDeploy();

        ForumAccount(payable(account)).initialize(
            entryPoint, owner, gnosisFallbackLibrary, authData, clientDataStart, clientDataEnd
        );
    }

    /// ----------------------------------------------------------------------------------------
    /// Factory Internal
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Get the address of an account that would be returned by createAccount()
     * @dev Salt should be keccak256(abi.encodePacked(owner)) where owner is the [x, y] public key for secp256r1 signer
     */
    function getAddress(bytes32 salt) public view returns (address clone) {
        return address(
            bytes20(keccak256(abi.encodePacked(bytes1(0xff), DETERMINISTIC_DEPLOYMENT_PROXY, salt, _createProxyDataHash)) << 96)
        );
    }
}
