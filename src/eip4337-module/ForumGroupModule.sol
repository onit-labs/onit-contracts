//SPDX-License-Identifier: GPL
pragma solidity ^0.8.7;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import {Forum4337Group} from './Forum4337Group.sol';

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';
import '@gnosis.pm/safe-contracts/contracts/base/Executor.sol';
import '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';
import '@eip4337/interfaces/IAccount.sol';
import '@eip4337/interfaces/IEntryPoint.sol';
import '@utils/Exec.sol';

using ECDSA for bytes32;

// !!!
// - Consider domain / chain info to be included in signatures
// - Integrate validation of sigs on elliptic contract
// - Make more addresses immutable to save gas
// !!!

/**
 * @notice Forum Group Module.
 * @dev - Called directly from entrypoint so must implement validateUserOp
 * 		- Holds an immutable reference to the EntryPoint
 * 		- Is enabled as a module on a Gnosis Safe
 * @author modified from infinitism https://github.com/eth-infinitism/account-abstraction/contracts/samples/gnosis/EIP4337Module.sol
 */
contract ForumGroupModule is Forum4337Group, IAccount, Executor {
	// The safe controlled by this module
	GnosisSafe public safe;

	address public immutable entryPoint;

	// Set to address(this) we can know the current 4337 module enabled on a safe
	address public this4337Module;

	address internal constant SENTINEL_MODULES = address(0x1);

	// return value in case of signature failure, with no time-range.
	// equivalent to _packValidationData(true,0,0);
	uint256 internal constant SIG_VALIDATION_FAILED = 1;

	/// -----------------------------------------------------------------------
	/// 						CONSTRUCTOR
	/// -----------------------------------------------------------------------

	constructor(address anEntryPoint) {
		entryPoint = anEntryPoint;
	}

	function setUp(address _safe, bytes memory _initializationParams) external initializer {
		this4337Module = address(this);

		safe = GnosisSafe(payable(_safe));

		setUpGroup(_initializationParams);
	}

	/**
	 * delegate-called (using execFromModule) through the fallback, so "real" msg.sender is attached as last 20 bytes
	 */
	function validateUserOp(
		UserOperation calldata userOp,
		bytes32 userOpHash,
		uint256 missingAccountFunds
	) external override returns (uint256 validationData) {
		address msgSender = address(bytes20(msg.data[msg.data.length - 20:]));
		require(msgSender == entryPoint, 'account: not from entrypoint');

		// GnosisSafe pThis = GnosisSafe(payable(address(this)));
		// bytes32 hash = userOpHash.toEthSignedMessageHash();
		// address recovered = hash.recover(userOp.signature);
		// require(threshold == 1, 'account: only threshold 1');
		// if (!pThis.isOwner(recovered)) {
		// 	validationData = SIG_VALIDATION_FAILED;
		// }

		// if (userOp.initCode.length == 0) {
		// 	require(uint256(nonce) == userOp.nonce, 'account: invalid nonce');
		// 	nonce = bytes32(uint256(nonce) + 1);
		// }

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
		//address msgSender = address(bytes20(msg.data[msg.data.length - 20:]));
		require(msg.sender == entryPoint, 'account: not from entrypoint');
		//require(msg.sender == eip4337Fallback, 'account: not from EIP4337Fallback');

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

	/**
	 * set up a safe as EIP-4337 enabled.
	 * called from the GnosisSafeAccountFactory during construction time
	 * - enable this module
	 * - this method is called with delegateCall, so the module (usually itself) is passed as parameter, and "this" is the safe itself
	 */
	function setup4337Module() external {
		GnosisSafe safe = GnosisSafe(payable(address(this)));

		require(
			!safe.isModuleEnabled(this4337Module),
			'setup4337Module: eip4337Module already enabled'
		);

		safe.enableModule(this4337Module);
	}

	/**
	 * replace EIP4337 module, to support a new EntryPoint.
	 * must be called using execTransaction and Enum.Operation.DelegateCall
	 * @param prevModule returned by getCurrentEIP4337Module
	 * @param oldModule the old EIP4337 module to remove, returned by getCurrentEIP4337Module
	 * @param newModule the new EIP4337Module, usually with a new EntryPoint
	 */
	function replaceEIP4337Module(
		address prevModule,
		ForumGroupModule oldModule,
		ForumGroupModule newModule
	) public {
		GnosisSafe pThis = GnosisSafe(payable(address(this)));

		require(
			pThis.isModuleEnabled(address(oldModule)),
			'replaceEIP4337Manager: oldModule is not active'
		);

		pThis.disableModule(prevModule, oldModule.this4337Module());

		pThis.enableModule(newModule.this4337Module());

		validateEip4337(pThis, newModule);
	}

	/**
	 * Validate this gnosisSafe is callable through the EntryPoint.
	 * the test is might be incomplete: we check that we reach our validateUserOp and fail on signature.
	 *  we don't test full transaction
	 */
	function validateEip4337(GnosisSafe safe, ForumGroupModule module) public {
		// this prevents mistaken replaceEIP4337Module to disable the module completely.
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
			revert('validateEip4337: handleOps must fail');
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

	/**
	 * enumerate modules, and find the currently active EIP4337 manager (and previous module)
	 * @return prev prev module, needed by replaceEIP4337Manager
	 * @return manager the current active EIP4337Manager
	 */
	function getCurrentEIP4337Manager(
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
}
