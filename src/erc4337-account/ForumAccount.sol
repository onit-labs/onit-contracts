// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {Safe, Enum} from "@safe/Safe.sol";

import {BaseAccount, IEntryPoint, UserOperation} from "@erc4337/core/BaseAccount.sol";

import {Base64} from "@libraries/Base64.sol";
import {FCL_Elliptic_ZZ} from "@libraries/FCL_Elliptic_ZZ.sol";

import {Exec} from "@utils/Exec.sol";

/**
 * @notice ERC4337 Managed Gnosis Safe Account Implementation
 * @author Forum (https://forumdaos.com)
 * @dev Uses infinitism style base 4337 interface, with gnosis safe account
 * @custom:warning This contract has not been audited, and is likely to change.
 */

/**
 * TODO
 * - Integrate domain seperator in validation of signatures
 * - Use as a module until more finalised version is completed (for easier upgradability)
 * - Consider a function to upgrade owner
 * - Add restriction to check entryPoint is valid before setting
 * - Further access control on functions
 * - Add guardians and account recovery (beyond basic method of adding an EOA owner to Safe)
 */
contract ForumAccount is Safe, BaseAccount {
    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT STORAGE
    /// ----------------------------------------------------------------------------------------

    // Entry point allowed to call methods directly on this contract
    IEntryPoint internal _entryPoint;

    address public immutable ellipticCurveVerifier;

    // Public key for secp256r1 signer
    uint256[2] internal _owner;

    string public constant ACCOUNT_VERSION = "v0.2.0";

    /// @dev Values used when public key signs a message
    /// To make this variable we can pass these with the user op signature, for now we save gas writing them on deploy
    struct SigningData {
        bytes authData;
        string clientDataStart;
        string clientDataEnd;
    }

    SigningData public signingData;

    /// ----------------------------------------------------------------------------------------
    ///							CONSTRUCTOR
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Constructor
     * @dev This contract should be deployed using a proxy, the constructor should not be called
     */
    constructor(address ellipticCurveVerifier_) {
        threshold = 1;

        ellipticCurveVerifier = ellipticCurveVerifier_;
    }

    /**
     * @notice Initialize the account
     * @param  entryPoint_ The entrypoint that can call methods directly on this contract
     * @param  owner_ The public key of the owner of this account
     * @param  gnosisFallbackLibrary The fallback handler for the Gnosis Safe
     * @dev This method should only be called once, and setup() will revert if already initialized
     */
    function initialize(
        address entryPoint_,
        uint256[2] memory owner_,
        address gnosisFallbackLibrary,
        bytes memory authData_,
        string memory clientDataStart_,
        string memory clientDataEnd_
    ) public virtual {
        _entryPoint = IEntryPoint(entryPoint_);

        _owner = owner_;

        signingData = SigningData(authData_, clientDataStart_, clientDataEnd_);

        // Owner must be passed to safe setup as an array of addresses
        address[] memory ownerPlaceholder = new address[](1);
        // Set dead address as owner, actions are controlled via this contract & entrypoint
        ownerPlaceholder[0] = address(0xdead);

        // Setup the Gnosis Safe - will revert if already initialized
        this.setup(
            ownerPlaceholder, 1, address(0), new bytes(0), gnosisFallbackLibrary, address(0), 0, payable(address(0))
        );
    }

    /// ----------------------------------------------------------------------------------------
    ///							ACCOUNT LOGIC
    /// ----------------------------------------------------------------------------------------

    /**
     * Execute a call but also revert if the execution fails.
     * The default behavior of the Safe is to not revert if the call fails,
     * which is challenging for integrating with ERC4337 because then the
     * EntryPoint wouldn't know to emit the UserOperationRevertReason event,
     * which the frontend/client uses to capture the reason for the failure.
     */
    function executeAndRevert(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) external payable {
        _requireFromEntryPoint();

        bool success = execute(to, value, data, operation, type(uint256).max);

        bytes memory returnData = Exec.getReturnData(type(uint256).max);
        // Revert with the actual reason string
        // Adopted from: https://github.com/Uniswap/v3-periphery/blob/464a8a49611272f7349c970e0fadb7ec1d3c1086/contracts/base/Multicall.sol#L16-L23
        if (!success) {
            if (returnData.length < 68) revert();
            assembly {
                returnData := add(returnData, 0x04)
            }
            revert(abi.decode(returnData, (string)));
        }
    }

    function setEntryPoint(IEntryPoint anEntryPoint) external virtual {
        _requireFromEntryPoint();

        _entryPoint = anEntryPoint;
    }

    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    function owner() public view virtual returns (uint256[2] memory) {
        return _owner;
    }

    /// ----------------------------------------------------------------------------------------
    ///							INTERNAL METHODS
    /// ----------------------------------------------------------------------------------------

    // TODO consider nonce validation in here as well in on v6 entrypoint

    /**
     * @notice Validate the signature of the user operation
     * @param userOp The user operation to validate
     * @param userOpHash The hash of the user operation
     * @return sigTimeRange The time range the signature is valid for
     * @dev This is a first take at getting the signature validation working using passkeys
     * - The signature may be validated using a domain seperator
     * - More efficient validation of the hashing and conversion of authData is needed
     */
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 sigTimeRange) {
        /**
         * @dev Validate the signature of the user operation.
         * Delegate call the ellipticCurveVerifier library address to call the ecdsa_verify function with parameters:
         * - Hash of the authenticator data, and full message hash (client data and userOpHash) signed by the passkey offchain
         * - The signature from the userOp
         * - The public key of the passkey
         */
        // (, bytes memory res) = ellipticCurveVerifier.delegatecall(
        //     abi.encodeWithSelector(
        //         FCL_Elliptic_ZZ.ecdsa_verify.selector,
        //         sha256(
        //             abi.encodePacked(
        //                 signingData.authData,
        //                 sha256(
        //                     abi.encodePacked(signingData.clientDataStart, Base64.encode(abi.encodePacked(userOpHash)), signingData.clientDataEnd)
        //                 )
        //             )
        //         ),
        //         [uint256(bytes32(userOp.signature[:32])), uint256(bytes32(userOp.signature[32:]))],
        //         [_owner[0], _owner[1]]
        //     )
        // );

        // // Check if the validator returns true, return SIG_VALIDATION_FAILED if not
        // return bytes32(res) == bytes32(uint256(1)) ? 0 : SIG_VALIDATION_FAILED;
    }
}
