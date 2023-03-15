// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */
/* solhint-disable no-console */

import {Base64} from '@libraries/Base64.sol';
import {HexToLiteralBytes} from '@libraries/HexToLiteralBytes.sol';

// Interface of the elliptic curve validator contract
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';

import '@gnosis/GnosisSafe.sol';

import '@erc4337/interfaces/IAccount.sol';
import '@erc4337/interfaces/IEntryPoint.sol';
import '@utils/Exec.sol';

import 'forge-std/console.sol';

// !!!
// ! correct checks on functions (ie. onlyEntryPoint)
// - Consider domain / chain info to be included in signatures
// - Integrate validation of sigs on elliptic contract
// - Make more addresses immutable to save gas
// !!!

/**
 * @notice Forum Group Module.
 * @dev - Called directly from entrypoint so must implement validateUserOp
 * 		- Holds an immutable reference to the EntryPoint
 * 		- Is enabled as a module on a Gnosis Safe
 * @author modified from infinitism https://github.com/eth-infinitism/account-abstraction/contracts/samples/gnosis/ERC4337Module.sol
 */
contract ForumGroup is IAccount, GnosisSafe {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS & ERRORS
	/// ----------------------------------------------------------------------------------------

	error ModuleAlreadySetUp();

	error NotFromEntrypoint();

	error InvalidInitialisation();

	error InvalidNonce();

	error InvalidThreshold();

	/// ----------------------------------------------------------------------------------------
	///							GROUP STORAGE
	/// ----------------------------------------------------------------------------------------

	// Immutable reference to validator of the secp256r1 signatures
	IEllipticCurveValidator internal immutable _ellipticCurveValidator;

	// Reference to latest entrypoint
	address internal _entryPoint;

	// Used to calculate percentages
	uint256 internal constant BASIS_POINTS = 10000;

	// Vote threshold to pass (basis points of 10,000 ie. 6,000 = 60%)
	uint256 public voteThreshold;

	// Return value in case of signature failure, with no time-range.
	// Equivalent to _packValidationData(true,0,0);
	uint256 internal constant SIG_VALIDATION_FAILED = 1;

	// TODO convert below x and y mappings to linked list
	// The public keys of the signing members of the group
	uint256[] internal _membersX;
	uint256[] internal _membersY;

	// Used nonces; 1 = used (prevents replaying the same userOp)
	mapping(uint256 => uint) internal usedNonces;

	/// -----------------------------------------------------------------------
	/// 						CONSTRUCTOR
	/// -----------------------------------------------------------------------

	constructor(address anEllipticCurveValidator, address anEntryPoint) {
		_ellipticCurveValidator = IEllipticCurveValidator(anEllipticCurveValidator);
	}

	/**
	 * @notice Setup the module.
	 * @dev - Called from the safe during the safe setup
	 * 		- Enables the entrypoint & fallback for the safe and sets up this module
	 * @param anEntryPoint The entrypoint to use on the safe
	 * @param fallbackHandler The fallback handler to use on the safe
	 * @param _voteThreshold Vote threshold to pass (basis points of 10,000 ie. 6,000 = 60%)
	 * @param membersX The public keys of the signing members of the group
	 * @param membersY The public keys of the signing members of the group
	 */
	function setUp(
		address anEntryPoint,
		address fallbackHandler,
		uint256 _voteThreshold,
		uint256[] memory membersX,
		uint256[] memory membersY
	) external {
		if (voteThreshold != 0) revert ModuleAlreadySetUp();

		_entryPoint = anEntryPoint;

		// Create a placeholder owner
		address[] memory ownerPlaceholder = new address[](1);
		ownerPlaceholder[0] = address(0xdead);

		// Setup the safe
		this.setup(
			ownerPlaceholder,
			1,
			address(0),
			new bytes(0),
			fallbackHandler,
			address(0),
			0,
			payable(address(0))
		);

		if (
			_voteThreshold <= 0 ||
			_voteThreshold > 10000 ||
			membersX.length <= 0 ||
			membersX.length != membersY.length
		) revert InvalidInitialisation();

		voteThreshold = _voteThreshold;

		_membersX = membersX;
		_membersY = membersY;
	}

	/// -----------------------------------------------------------------------
	/// 						EXECUTION
	/// -----------------------------------------------------------------------

	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 validationData) {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// Extract the passkey generated signature and authentacator data
		(uint256[2][] memory sig, string memory authData) = abi.decode(
			userOp.signature,
			(uint256[2][], string)
		);

		// Hash the client data to produce the challenge signed by the passkey offchain
		bytes32 hashedClientData = sha256(
			abi.encodePacked(
				'{"type":"webauthn.get","challenge":"',
				Base64.encode(abi.encodePacked(userOpHash)),
				'","origin":"https://development.forumdaos.com"}'
			)
		);

		bytes32 fullMessage = sha256(
			abi.encodePacked(HexToLiteralBytes.fromHex(authData), hashedClientData)
		);

		uint256 len = _membersX.length;

		uint256 count;

		// ! Update this to avoid needing to pass empty sigs
		for (uint i; i < len; ) {
			// Check if the signature is not empty, check if it's valid
			if (
				sig[i][0] != 0 &&
				_ellipticCurveValidator.validateSignature(
					fullMessage,
					[sig[i][0], sig[i][1]],
					[_membersX[i], _membersY[i]]
				)
			) ++count;

			++i;
		}

		// Take the ceiling of the division (ie. 1.1 => 2 votes are needed to pass)
		if (count < (len * voteThreshold + BASIS_POINTS - 1) / BASIS_POINTS) {
			validationData = SIG_VALIDATION_FAILED;
		}

		// TODO improve used nonce tracking
		if (userOp.initCode.length == 0) {
			if (usedNonces[userOp.nonce] == 1) revert InvalidNonce();
			usedNonces[userOp.nonce] == 1;
			++nonce;
		}

		if (missingAccountFunds > 0) {
			//Note: MAY pay more than the minimum, to deposit for future transactions
			(bool success, ) = payable(msg.sender).call{value: missingAccountFunds}('');
			(success);
			//ignore failure (its EntryPoint's job to verify, not account.)
		}
	}

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
	) external {
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
	/// 						MODULE MANAGEMENT
	/// -----------------------------------------------------------------------

	function setThreshold(uint256 threshold) external {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		if (threshold <= 0 || threshold > 10000) revert InvalidThreshold();

		voteThreshold = threshold;
	}

	function addMember(uint256 x, uint256 y) external {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		_membersX.push(x);
		_membersY.push(y);
	}

	function setEntryPoint(address anEntryPoint) external authorized {
		if (msg.sender != _entryPoint) revert NotFromEntrypoint();

		// ! consider checks that entrypoint is valid here !
		// ! potential to brick account !
		_entryPoint = anEntryPoint;
	}

	/// -----------------------------------------------------------------------
	/// 						VIEW FUNCTIONS
	/// -----------------------------------------------------------------------

	function entryPoint() public view virtual returns (address) {
		return _entryPoint;
	}

	function getMembers() public view returns (uint256[2][] memory members) {
		uint256 len = _membersX.length;
		members = new uint256[2][](len);
		for (uint i; i < len; ) {
			members[i] = [_membersX[i], _membersY[i]];
			++i;
		}
	}
}
