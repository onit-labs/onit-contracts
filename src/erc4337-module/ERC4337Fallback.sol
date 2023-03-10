//SPDX-License-Identifier: GPL
pragma solidity ^0.8.7;

/* solhint-disable no-inline-assembly */

import {DefaultCallbackHandler} from '@gnosis/handler/DefaultCallbackHandler.sol';
import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {IAccount, UserOperation} from '@erc4337/interfaces/IAccount.sol';
import {ForumGroupModule} from './ForumGroupModule.sol';

using ECDSA for bytes32;

/**
 * This 'fallbackHandler' adds an implementation of 'validateUserOp' to the GnosisSafe.
 * Upon receiving the 'validateUserOp', a Safe with ERC4337Fallback enabled makes a 'delegatecall' to ForumGroupModule.
 * The implementation of the 'validateUserOp' method is located in the ForumGroupModule.
 * @author Forum DAOs - modified from infinitism https://github.com/eth-infinitism/account-abstraction/contracts/samples/gnosis/ERC4337Fallback.sol
 */
contract ERC4337Fallback is DefaultCallbackHandler, IAccount, IERC1271 {
	bytes4 internal constant ERC1271_MAGIC_VALUE = 0x1626ba7e;

	address public immutable erc4337module;

	constructor(address _erc4337module) {
		erc4337module = _erc4337module;
	}

	/**
	 * delegate the contract call to the ForumGroupModule
	 */
	function delegateToModule() internal returns (bytes memory) {
		// delegate entire msg.data (including the appended "msg.sender") to the ForumGroupModule
		// will work only for GnosisSafe contracts
		GnosisSafe safe = GnosisSafe(payable(msg.sender));
		(bool success, bytes memory ret) = safe.execTransactionFromModuleReturnData(
			erc4337module,
			0,
			msg.data,
			Enum.Operation.DelegateCall
		);
		if (!success) {
			assembly {
				revert(add(ret, 32), mload(ret))
			}
		}
		return ret;
	}

	/**
	 * called from the Safe. delegate actual work to ForumGroupModule
	 */
	function validateUserOp(
		UserOperation calldata,
		bytes32,
		uint256
	) external override returns (uint256 deadline) {
		bytes memory ret = delegateToModule();
		return abi.decode(ret, (uint256));
	}

	/**
	 * called from the Safe. delegate actual work to ForumGroupModule
	 */
	function executeAndRevert(address, uint256, bytes memory, Enum.Operation) external {
		delegateToModule();
	}

	function isValidSignature(
		bytes32 _hash,
		bytes memory _signature
	) external view override returns (bytes4) {
		bytes32 hash = _hash.toEthSignedMessageHash();
		address recovered = hash.recover(_signature);

		GnosisSafe safe = GnosisSafe(payable(address(msg.sender)));

		// Validate signatures
		if (safe.isOwner(recovered)) {
			return ERC1271_MAGIC_VALUE;
		} else {
			return 0xffffffff;
		}
	}
}
