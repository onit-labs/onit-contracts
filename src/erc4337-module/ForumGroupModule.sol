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
import '@gnosis/examples/libraries/GnosisSafeStorage.sol';

import '@erc4337/interfaces/IAccount.sol';
import '@erc4337/interfaces/IEntryPoint.sol';
import '@utils/Exec.sol';

import './ERC4337Fallback.sol';

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
contract ForumGroupModule is IAccount, GnosisSafeStorage, Executor {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS & ERRORS
	/// ----------------------------------------------------------------------------------------

	error ModuleAlreadySetUp();

	error ModuleAlreadyEnabled();

	error NotFromEntrypoint();

	error InvalidInitialisation();

	error InvalidNonce();

	error InvalidThreshold();

	/// ----------------------------------------------------------------------------------------
	///							MODULE STORAGE
	/// ----------------------------------------------------------------------------------------

	// The safe controlled by this module
	GnosisSafe public safe;

	// Immutable reference to validator of the secp256r1 signatures
	IEllipticCurveValidator internal immutable _ellipticCurveValidator;

	// Immutable reference to latest entrypoint
	address public immutable entryPoint;

	// Reference to fallback module for the safe ! TODO make immutable
	address public erc4337Fallback;

	// Set to address(this) so we can know the current 4337 module enabled on a safe
	address public this4337Module;

	address internal constant SENTINEL_MODULES = address(0x1);

	// Used to calculate percentages
	uint256 internal constant BASIS_POINTS = 10000;

	// Vote threshold to pass (basis points of 10,000 ie. 6,000 = 60%)
	uint256 public voteThreshold;

	// return value in case of signature failure, with no time-range.
	// equivalent to _packValidationData(true,0,0);
	uint256 internal constant SIG_VALIDATION_FAILED = 1;

	// TODO convert below x and y mappings to linked list

	// The public keys of the signing members of the group
	uint256[] internal membersX;
	uint256[] internal membersY;

	// Used nonces; 1 = used (prevents replaying the same userOp)
	mapping(uint256 => uint) internal usedNonces;

	/// -----------------------------------------------------------------------
	/// 						CONSTRUCTOR
	/// -----------------------------------------------------------------------

	constructor(address ellipticCurveValidator, address anEntryPoint) {
		_ellipticCurveValidator = IEllipticCurveValidator(ellipticCurveValidator);

		entryPoint = anEntryPoint;
	}

	/**
	 * @notice Setup the module.
	 * @dev - Called from the safe during the safe setup
	 * 		- Enables the entrypoint & fallback for the safe and sets up this module
	 * @param _voteThreshold Vote threshold to pass (basis points of 10,000 ie. 6,000 = 60%)
	 * @param _membersX The public keys of the signing members of the group
	 * @param _membersY The public keys of the signing members of the group
	 * @dev TODO use setup via proxy instead of deploying & calling this (check setup is sufficiently protected)
	 */
	function setUp(
		address _erc4337Fallback,
		uint256 _voteThreshold,
		uint256[] memory _membersX,
		uint256[] memory _membersY
	) external {
		if (voteThreshold != 0) revert ModuleAlreadySetUp();

		// Set the fallback
		erc4337Fallback = _erc4337Fallback;

		if (
			_voteThreshold <= 0 ||
			_voteThreshold > 10000 ||
			_membersX.length <= 0 ||
			_membersX.length != _membersY.length
		) revert InvalidInitialisation();

		voteThreshold = _voteThreshold;

		membersX = _membersX;
		membersY = _membersY;
	}

	function setUpModules() external {
		if (voteThreshold != 0) revert ModuleAlreadySetUp();

		safe = GnosisSafe(payable(msg.sender));

		if (safe.isModuleEnabled(entryPoint)) revert ModuleAlreadyEnabled();

		if (safe.isModuleEnabled(erc4337Fallback)) revert ModuleAlreadyEnabled();

		safe.enableModule(entryPoint);
		safe.enableModule(erc4337Fallback);
	}

	/// -----------------------------------------------------------------------
	/// 						EXECUTION
	/// -----------------------------------------------------------------------

	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 validationData) {
		address msgSender = address(bytes20(msg.data[msg.data.length - 20:]));
		if (msgSender != entryPoint) revert NotFromEntrypoint();

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

		uint256 len = membersX.length;

		uint256 count;

		// ! Update this to avoid needing to pass empty sigs
		for (uint i; i < len; ) {
			// Check if the signature is not empty, check if it's valid
			if (
				sig[i][0] != 0 &&
				_ellipticCurveValidator.validateSignature(
					fullMessage,
					[sig[i][0], sig[i][1]],
					[membersX[i], membersY[i]]
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
			nonce = bytes32(uint256(nonce) + 1);
			usedNonces[userOp.nonce] == 1;
			//++nonce;
		}

		if (missingAccountFunds > 0) {
			//Note: MAY pay more than the minimum, to deposit for future transactions
			(bool success, ) = payable(msgSender).call{value: missingAccountFunds}('');
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
		// Entry point calls this method directly, and from here we call the safe
		address msgSender = address(bytes20(msg.data[msg.data.length - 20:]));
		if (msgSender != entryPoint) revert NotFromEntrypoint();
		require(msg.sender == erc4337Fallback, 'account: not from ERC4337Fallback');

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
		// require(msg.sender == entryPoint, 'account: not from entrypoint');

		if (threshold <= 0 || threshold > 10000) revert InvalidThreshold();

		voteThreshold = threshold;
	}

	// ! correct visibility and set initial members in factory
	function addMember(uint256 x, uint256 y) public {
		// require(msg.sender == entryPoint, 'account: not from entrypoint');

		membersX.push(x);
		membersY.push(y);
	}

	// /**
	//  * replace ERC4337 module, to support a new EntryPoint.
	//  * must be called using execTransaction and Enum.Operation.DelegateCall
	//  * @param prevModule returned by getCurrentERC4337Module
	//  * @param oldModule the old ERC4337 module to remove, returned by getCurrentERC4337Module
	//  * @param newModule the new ERC4337Module, usually with a new EntryPoint
	//  */
	// function replaceERC4337Module(
	// 	address prevModule,
	// 	ForumGroupModule oldModule,
	// 	ForumGroupModule newModule
	// ) public {
	// 	GnosisSafe pThis = GnosisSafe(payable(address(this)));

	// 	require(
	// 		pThis.isModuleEnabled(address(oldModule)),
	// 		'replaceERC4337Manager: oldModule is not active'
	// 	);

	// 	pThis.disableModule(prevModule, oldModule.this4337Module());

	// 	pThis.enableModule(newModule.this4337Module());

	// 	validateErc4337(pThis, newModule);
	// }

	// /**
	//  * Validate this gnosisSafe is callable through the EntryPoint.
	//  * the test is might be incomplete: we check that we reach our validateUserOp and fail on signature.
	//  *  we don't test full transaction
	//  */
	// function validateErc4337(GnosisSafe safe, ForumGroupModule module) public {
	// 	// this prevents mistaken replaceERC4337Module to disable the module completely.
	// 	// minimal signature that pass "recover"
	// 	bytes memory sig = new bytes(65);
	// 	sig[64] = bytes1(uint8(27));
	// 	sig[2] = bytes1(uint8(1));
	// 	sig[35] = bytes1(uint8(1));
	// 	UserOperation memory userOp = UserOperation(
	// 		address(safe),
	// 		uint256(safe.nonce()),
	// 		'',
	// 		'',
	// 		0,
	// 		1000000,
	// 		0,
	// 		0,
	// 		0,
	// 		'',
	// 		sig
	// 	);
	// 	UserOperation[] memory userOps = new UserOperation[](1);
	// 	userOps[0] = userOp;
	// 	IEntryPoint _entryPoint = IEntryPoint(payable(module.entryPoint()));
	// 	try _entryPoint.handleOps(userOps, payable(msg.sender)) {
	// 		revert('validateErc4337: handleOps must fail');
	// 	} catch (bytes memory error) {
	// 		if (
	// 			keccak256(error) !=
	// 			keccak256(
	// 				abi.encodeWithSignature('FailedOp(uint256,string)', 0, 'AA24 signature error')
	// 			)
	// 		) {
	// 			revert(string(error));
	// 		}
	// 	}
	// }

	/// -----------------------------------------------------------------------
	/// 						VIEW FUNCTIONS
	/// -----------------------------------------------------------------------

	/**
	 * enumerate modules, and find the currently active ERC4337 manager (and previous module)
	 * @return prev prev module, needed by replaceERC4337Manager
	 * @return manager the current active ERC4337Manager
	 */
	function getCurrentERC4337Manager(
		GnosisSafe _safe
	) public view returns (address prev, address manager) {
		prev = address(SENTINEL_MODULES);
		(address[] memory modules, ) = _safe.getModulesPaginated(SENTINEL_MODULES, 100);
		for (uint i = 0; i < modules.length; i++) {
			address module = modules[i];
			try ForumGroupModule(payable(module)).this4337Module() returns (address _manager) {
				return (prev, _manager);
			} catch // solhint-disable-next-line no-empty-blocks
			{

			}
			prev = module;
		}
		return (address(0), address(0));
	}

	function getMembers() public view returns (uint256[2][] memory members) {
		members = new uint256[2][](membersX.length);
		for (uint i; i < membersX.length; ) {
			members[i] = [membersX[i], membersY[i]];
			++i;
		}
	}
}
