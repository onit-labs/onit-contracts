//SPDX-License-Identifier: GPL
pragma solidity ^0.8.7;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */
/* solhint-disable no-console */

import {Base64} from '@libraries/Base64.sol';

// Interface of the elliptic curve validator contract
import {IEllipticCurveValidator} from '@interfaces/IEllipticCurveValidator.sol';

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';
import '@gnosis.pm/safe-contracts/contracts/base/Executor.sol';
import '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';

import '@erc4337/interfaces/IAccount.sol';
import '@erc4337/interfaces/IEntryPoint.sol';
import '@utils/Exec.sol';

import './ERC4337Fallback.sol';

import 'forge-std/console.sol';

// !!!
// - Consider domain / chain info to be included in signatures
// - Integrate validation of sigs on elliptic contract
// - Make more addresses immutable to save gas
// - Convert to custom errors
// !!!

/**
 * @notice Forum Group Module.
 * @dev - Called directly from entrypoint so must implement validateUserOp
 * 		- Holds an immutable reference to the EntryPoint
 * 		- Is enabled as a module on a Gnosis Safe
 * @author modified from infinitism https://github.com/eth-infinitism/account-abstraction/contracts/samples/gnosis/ERC4337Module.sol
 */
contract ForumGroupModule is IAccount, Executor, Initializable {
	// The safe controlled by this module
	GnosisSafe public safe;

	// Immutable reference to validator of the secp256r1 signatures
	IEllipticCurveValidator internal immutable _ellipticCurveValidator;

	// Immutable reference to latest entrypoint
	address public immutable entryPoint;

	// Immutable reference to fallback module for the safe
	address public immutable erc4337Fallback;

	// Set to address(this) so we can know the current 4337 module enabled on a safe
	address public this4337Module;

	address internal constant SENTINEL_MODULES = address(0x1);

	// The nonce of the account
	uint256 public nonce;

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

	/// -----------------------------------------------------------------------
	/// 						CONSTRUCTOR
	/// -----------------------------------------------------------------------

	constructor(IEllipticCurveValidator ellipticCurveValidator, address anEntryPoint) {
		_ellipticCurveValidator = ellipticCurveValidator;

		entryPoint = anEntryPoint;

		//! check address(this) here
		erc4337Fallback = address(new ERC4337Fallback(address(this)));
	}

	/**
	 * @notice Setup the module.
	 * @dev - Called from the GnosisSafeAccountFactory during construction time
	 * 		- Enable this module
	 * 		- This method is called with delegateCall, so the module (usually itself) is passed as parameter, and "this" is the safe itself
	 * @param module The module to be enabled (should be this address)
	 * @param _voteThreshold Vote threshold to pass (basis points of 10,000 ie. 6,000 = 60%)
	 * @param _membersX The public keys of the signing members of the group
	 * @param _membersY The public keys of the signing members of the group
	 * @dev TODO use setup via proxy instead of deploying & calling this
	 */
	function setUp(
		ForumGroupModule module,
		uint256 _voteThreshold,
		uint256[] memory _membersX,
		uint256[] memory _membersY
	) external initializer {
		safe = GnosisSafe(payable(address(this)));

		require(
			!safe.isModuleEnabled(module.entryPoint()),
			'setup4337Modules: entrypoint already enabled'
		);
		require(
			!safe.isModuleEnabled(module.erc4337Fallback()),
			'setup4337Modules: eip4337Fallback already enabled'
		);

		safe.enableModule(module.entryPoint());
		safe.enableModule(module.erc4337Fallback());

		require(
			_voteThreshold > 0 &&
				_voteThreshold <= 10000 &&
				_membersX.length > 0 &&
				_membersY.length > 0 &&
				_membersX.length == _membersY.length,
			'account: invalid setup params'
		);

		voteThreshold = _voteThreshold;

		membersX = _membersX;
		membersY = _membersY;
	}

	/// -----------------------------------------------------------------------
	/// 						EXECUTION
	/// -----------------------------------------------------------------------

	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 validationData) {
		require(msg.sender == entryPoint, 'account: not from entrypoint');

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

		bytes32 fullMessage = sha256(abi.encodePacked(fromHex(authData), hashedClientData));

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

		if (userOp.initCode.length == 0) {
			require(nonce == userOp.nonce, 'account: invalid nonce');
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
	function execute(
		address to,
		uint256 value,
		bytes memory data,
		Enum.Operation operation
	) external {
		// Entry point calls this method directly, and from here we call the safe
		//address msgSender = address(bytes20(msg.data[msg.data.length - 20:]));
		require(msg.sender == entryPoint, 'account: not from entrypoint');
		//require(msg.sender == erc4337Fallback, 'account: not from ERC4337Fallback');

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
		require(msg.sender == entryPoint, 'account: not from entrypoint');

		require(threshold > 0 && threshold <= 10000, 'account: invalid threshold');

		voteThreshold = threshold;
	}

	/**
	 * replace ERC4337 module, to support a new EntryPoint.
	 * must be called using execTransaction and Enum.Operation.DelegateCall
	 * @param prevModule returned by getCurrentERC4337Module
	 * @param oldModule the old ERC4337 module to remove, returned by getCurrentERC4337Module
	 * @param newModule the new ERC4337Module, usually with a new EntryPoint
	 */
	function replaceERC4337Module(
		address prevModule,
		ForumGroupModule oldModule,
		ForumGroupModule newModule
	) public {
		GnosisSafe pThis = GnosisSafe(payable(address(this)));

		require(
			pThis.isModuleEnabled(address(oldModule)),
			'replaceERC4337Manager: oldModule is not active'
		);

		pThis.disableModule(prevModule, oldModule.this4337Module());

		pThis.enableModule(newModule.this4337Module());

		validateErc4337(pThis, newModule);
	}

	/**
	 * Validate this gnosisSafe is callable through the EntryPoint.
	 * the test is might be incomplete: we check that we reach our validateUserOp and fail on signature.
	 *  we don't test full transaction
	 */
	function validateErc4337(GnosisSafe safe, ForumGroupModule module) public {
		// this prevents mistaken replaceERC4337Module to disable the module completely.
		// minimal signature that pass "recover"
		bytes memory sig = new bytes(65);
		sig[64] = bytes1(uint8(27));
		sig[2] = bytes1(uint8(1));
		sig[35] = bytes1(uint8(1));
		UserOperation memory userOp = UserOperation(
			address(safe),
			uint256(safe.nonce()),
			'',
			'',
			0,
			1000000,
			0,
			0,
			0,
			'',
			sig
		);
		UserOperation[] memory userOps = new UserOperation[](1);
		userOps[0] = userOp;
		IEntryPoint _entryPoint = IEntryPoint(payable(module.entryPoint()));
		try _entryPoint.handleOps(userOps, payable(msg.sender)) {
			revert('validateErc4337: handleOps must fail');
		} catch (bytes memory error) {
			if (
				keccak256(error) !=
				keccak256(
					abi.encodeWithSignature('FailedOp(uint256,string)', 0, 'AA24 signature error')
				)
			) {
				revert(string(error));
			}
		}
	}

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

	/// -----------------------------------------------------------------------
	/// 						INTERNAL FUNCTIONS
	/// -----------------------------------------------------------------------

	// Convert an hexadecimal string to raw bytes
	function fromHex(string memory s) internal pure returns (bytes memory) {
		bytes memory ss = bytes(s);
		require(ss.length % 2 == 0, 'hex length not even');
		bytes memory r = new bytes(ss.length / 2);
		for (uint i = 0; i < ss.length / 2; ++i) {
			r[i] = bytes1(fromHexChar(uint8(ss[2 * i])) * 16 + fromHexChar(uint8(ss[2 * i + 1])));
		}
		return r;
	}

	// Convert an hexadecimal character to their value
	function fromHexChar(uint8 c) internal pure returns (uint8) {
		if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
			return c - uint8(bytes1('0'));
		}
		if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
			return 10 + c - uint8(bytes1('a'));
		}
		if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
			return 10 + c - uint8(bytes1('A'));
		}
		revert('failed hex conversion');
	}
}
