// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Module, Enum} from '@gnosis.pm/zodiac/contracts/core/Module.sol';

// Gnosis Safe imports
import {GnosisSafe} from '@gnosis/GnosisSafe.sol';
import {CompatibilityFallbackHandler} from '@gnosis/handler/CompatibilityFallbackHandler.sol';
import {MultiSend} from '@gnosis/libraries/MultiSend.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';
import {SignMessageLib} from '@gnosis/examples/libraries/SignMessage.sol';

// Forum 4337 contracts
import {ForumSafeModule} from '../../src/gnosis-forum/ForumSafeModule.sol';

// Forum interfaces
import {IForumSafeModuleTypes} from '../../src/interfaces/IForumSafeModuleTypes.sol';

// Config for the Safe which the Forum Module will attach to
abstract contract SafeTestConfig {
	// Safe contract types
	GnosisSafe internal safeSingleton;
	MultiSend internal multisend;
	CompatibilityFallbackHandler internal handler;
	GnosisSafeProxyFactory internal safeProxyFactory;
	SignMessageLib internal signMessageLib;

	// Used to store the address of the safe created in tests
	address internal safeAddress;

	/// -----------------------------------------------------------------------
	/// Setup
	/// -----------------------------------------------------------------------

	constructor() {
		safeSingleton = new GnosisSafe();
		multisend = new MultiSend();
		handler = new CompatibilityFallbackHandler();
		safeProxyFactory = new GnosisSafeProxyFactory();
		signMessageLib = new SignMessageLib();
	}

	/// -----------------------------------------------------------------------
	/// Utils
	/// -----------------------------------------------------------------------

	function buildSafeMultisend(
		Enum.Operation operation,
		address to,
		uint256 value,
		bytes memory data
	) internal pure returns (bytes memory) {
		// Encode the multisend transaction
		// (needed to delegate call from the safe as addModule is 'authorised')
		bytes memory tmp = abi.encodePacked(operation, to, value, uint256(data.length), data);

		// Create multisend payload
		return abi.encodeWithSignature('multiSend(bytes)', tmp);
	}
}
