// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/* solhint-disable avoid-low-level-calls */

import {Base64} from "@libraries/Base64.sol";
import {FCL_Elliptic_ZZ} from "@libraries/FCL_Elliptic_ZZ.sol";

import {Exec} from "@utils/Exec.sol";
import {MemberManager} from "@utils/MemberManager.sol";

import {IAccount} from "@erc4337/interfaces/IAccount.sol";
import {UserOperation} from "@erc4337/interfaces/IEntryPoint.sol";

import {Safe, Enum} from "@safe/Safe.sol";

/**
 * @title Forum Group
 * @notice A group 4337 wallet based on eth-infinitism IAccount, built on safe
 * @author Forum (https://github.com/forumdaos/contracts)
 * @custom:warning This contract has not been audited, and is likely to change.
 */

/**
 * TODO
 * - Add moduleAdmin function to handle adding members, changing threshold etc
 * - Add extension function to call extensions without needing full validation
 * - Add governance 1155
 * - Add check to prevent setting wrong entrypoint
 * - Consider alt signing method as gas is restricting max group size
 * - Open to signing from other clients (for now we set client & auth data for Forum on deploy)
 */

contract ForumGroup is IAccount, Safe, MemberManager {
    /// ----------------------------------------------------------------------------------------
    ///							EVENTS & ERRORS
    /// ----------------------------------------------------------------------------------------

    error NotFromEntrypoint();

    error InvalidInitialisation();

    error InvalidSigner();

    /// ----------------------------------------------------------------------------------------
    ///							GROUP STORAGE
    /// ----------------------------------------------------------------------------------------

    // Reference to latest entrypoint
    address internal _entryPoint;

    address public immutable ellipticCurveVerifier;

    // Return value in case of signature failure, with no time-range.
    // Equivalent to _packValidationData(true,0,0);
    uint256 internal constant _SIG_VALIDATION_FAILED = 1;

    string public constant GROUP_VERSION = "v0.2.0";

    /// @dev Values used when signing the transaction
    /// To make this variable we can pass these with the user op signature, for now we save gas writing them on deploy
    struct SigningData {
        bytes authData;
        string clientDataStart;
        string clientDataEnd;
    }

    SigningData public signingData;

    /// -----------------------------------------------------------------------
    /// 						SETUP
    /// -----------------------------------------------------------------------

    constructor(address singletonAccount_, address ellipticCurveVerifier_) MemberManager(singletonAccount_) {
        // Set the threshold on the safe, prevents calling initalise so good for singleton
        threshold = 1;

        ellipticCurveVerifier = ellipticCurveVerifier_;
    }

    /**
     * @notice Setup the group account.
     * @param entryPoint_ The entrypoint to use on the safe
     * @param fallbackHandler The fallback handler to use on the safe
     * @param voteThreshold_ Vote threshold to pass (counted in members)
     * @param members_ The public key pairs of the signing members of the group
     * @dev This function is only callable once, and is used to set up the group (setup will revert if called again)
     */
    function initalize(
        address entryPoint_,
        address fallbackHandler,
        uint256 voteThreshold_,
        uint256[2][] memory members_,
        bytes memory authData_,
        string memory clientDataStart_,
        string memory clientDataEnd_
    )
        external
    {
        // Create a placeholder owner
        address[] memory ownerPlaceholder = new address[](1);
        ownerPlaceholder[0] = address(0xdead);

        // Setup the safe with placeholder owner and threshold 1
        this.setup(ownerPlaceholder, 1, address(0), new bytes(0), fallbackHandler, address(0), 0, payable(address(0)));

        uint256 len = members_.length;

        if (entryPoint_ == address(0) || voteThreshold_ < 1 || voteThreshold_ > len || len < 1) revert
            InvalidInitialisation();

        _entryPoint = entryPoint_;

        _voteThreshold = voteThreshold_;

        // Set up the members
        for (uint256 i; i < len;) {
            // Create a hash used to identify the member
            address membersAddress = publicKeyAddress(Member(members_[i][0], members_[i][1]));

            // Add key pair to the members mapping
            _members[membersAddress] = Member(members_[i][0], members_[i][1]);
            // Add hash to the members array
            _membersAddressArray.push(membersAddress);

            unchecked {
                ++i;
            }
        }

        signingData = SigningData(authData_, clientDataStart_, clientDataEnd_);
    }

    /// -----------------------------------------------------------------------
    /// 						VALIDATION
    /// -----------------------------------------------------------------------

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        override
        returns (uint256 validationData)
    {
        if (msg.sender != _entryPoint) revert NotFromEntrypoint();

        // The full message signed by the passkey is the authData and the hashed client data
        bytes32 fullMessage = sha256(
            abi.encodePacked(
                signingData.authData,
                // Hash the packed client data & userOpHash to produce the challenge signed by the passkey offchain
                sha256(
                    abi.encodePacked(signingData.clientDataStart, Base64.encode(abi.encodePacked(userOpHash)), signingData.clientDataEnd)
                )
            )
        );

        /**
         * @dev userOp.signature is made up of 2 parts
         * 1) The first word (32 bytes) encodes info about the signers:
         *		- The first byte shows how may signers voted
         *		- The next n bytes are the index of each signer in the members array
         *		- The indexes are ordered in ascending order (lowest shifted 8 bits, highest shifted 8 * n bits)
         * 2) The rest of the bytes are the signatures of each signer
         *		- Each signature is 64 bytes (32 bytes for each of the r, s coordinates)
         */

        // The first word encodes info about the signers (how many signed, and their indexes)
        uint256 signerInfo = uint256(bytes32(userOp.signature[:32]));

        // Tracks how many votes have been verified
        uint256 count;

        // Tracks latest signerIndex, used to prevent duplicate sigs from same member
        uint256 latestIndex;

        // Casting as uint8 gives the first byte of signerInfo
        for (uint256 i; i < uint8(signerInfo);) {
            // Get the signerIndex of the current signer from the signerInfo
            uint256 signerIndex = uint8(signerInfo >> (8 * (i + 1)));

            // Check if the signerIndex is valid (we add one since latestIndex is initialised to 0)
            if (signerIndex + 1 <= latestIndex) revert InvalidSigner();

            // Offset for signatues should start from 32 and increase by 64 each time
            uint256 offset = 32 + (signerIndex * 64);

            /**
             * @dev Validate the signature of the user operation.
             * Delegate call the ellipticCurveVerifier library address to call the ecdsa_verify function with parameters:
             * - Full message signed by the passkey
             * - Signature from the userOp
             * - Public key of the passkey
             */
            (, bytes memory res) = ellipticCurveVerifier.delegatecall(
                abi.encodeWithSelector(
                    FCL_Elliptic_ZZ.ecdsa_verify.selector,
                    fullMessage,
                    [uint256(bytes32(userOp.signature[offset:])), uint256(bytes32(userOp.signature[offset + 32:]))],
                    [_members[_membersAddressArray[signerIndex]].x, _members[_membersAddressArray[signerIndex]].y]
                )
            );

            // Check if the signature is valid and increment count if so
            if (bytes32(res) == bytes32(uint256(1))) ++count;

            latestIndex = signerIndex + 1;
            ++i;
        }

        if (count < _voteThreshold) {
            validationData = _SIG_VALIDATION_FAILED;
        }

        // TODO consider further nonce checks in here

        if (missingAccountFunds > 0) {
            //Note: MAY pay more than the minimum, to deposit for future transactions
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds}("");
            (success); //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

    /// -----------------------------------------------------------------------
    /// 						EXECUTION
    /// -----------------------------------------------------------------------

    /**
     * Execute a call but also revert if the execution fails.
     * The default behavior of the Safe is to not revert if the call fails,
     * which is challenging for integrating with ERC4337 because then the
     * EntryPoint wouldn't know to emit the UserOperationRevertReason event,
     * which the frontend/client uses to capture the reason for the failure.
     */
    function executeAndRevert(address to, uint256 value, bytes memory data, Enum.Operation operation) external {
        if (msg.sender != _entryPoint) revert NotFromEntrypoint();

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

    /// -----------------------------------------------------------------------
    /// 						GROUP MANAGEMENT
    /// -----------------------------------------------------------------------

    function setEntryPoint(address entryPoint_) external {
        if (msg.sender != _entryPoint) revert NotFromEntrypoint();

        // ! consider checks that entrypoint is valid here !
        // ! potential to brick account !
        _entryPoint = entryPoint_;
    }

    /// -----------------------------------------------------------------------
    /// 						VIEW FUNCTIONS
    /// -----------------------------------------------------------------------

    function entryPoint() public view virtual returns (address) {
        return _entryPoint;
    }
}
