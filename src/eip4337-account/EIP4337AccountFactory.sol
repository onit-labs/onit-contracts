// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';

import '@openzeppelin/contracts/utils/Create2.sol';
import '@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol';

import {EIP4337Account, IEntryPoint} from './EIP4337Account.sol';

/// @notice Factory to deploy forum group.
contract EIP4337AccountFactory {
	/// ----------------------------------------------------------------------------------------
	/// Errors and Events
	/// ----------------------------------------------------------------------------------------

	event ForumSafeDeployed(
		EIP4337Account indexed forumGroup,
		address indexed gnosisSafe,
		string name,
		string symbol,
		address[] voters,
		uint32[2] govSettings
	);

	error NullDeploy();

	error EnableModuleFailed();

	/// ----------------------------------------------------------------------------------------
	/// Factory Storage
	/// ----------------------------------------------------------------------------------------

	// Template contract to use for new individual 4337 forum accounts
	EIP4337Account public immutable eip4337AccountSingleton;

	// Entry point used for 4337 accounts
	IEntryPoint public immutable entryPoint;

	// Fallback handler for Gnosis Safe
	address public immutable gnosisFallbackLibrary;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(
		EIP4337Account _eip4337AccountSingleton,
		IEntryPoint _entryPoint,
		address _gnosisFallbackLibrary
	) {
		eip4337AccountSingleton = _eip4337AccountSingleton;

		entryPoint = _entryPoint;

		gnosisFallbackLibrary = _gnosisFallbackLibrary;
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Deploys a new forum group and a new Gnosis safe
	 * @param owner Public key for secp256r1 signer
	 * @return account The deployed account
	 */
	function createAccount(
		uint salt,
		uint[2] calldata owner
	) external payable virtual returns (address payable account) {
		address addr = getAddress(salt, owner);
		uint codeSize = addr.code.length;
		if (codeSize > 0) {
			return payable(addr);
		}

		account = payable(
			new ERC1967Proxy{salt: bytes32(salt)}(
				address(eip4337AccountSingleton),
				abi.encodeCall(eip4337AccountSingleton.initialize, (entryPoint, owner))
			)
		);

		address[] memory arrayOwner = new address[](1);
		arrayOwner[0] = address(uint160(owner[0]));

		// Call setup on safe adding owner and threshold
		EIP4337Account(account).setup(
			arrayOwner, // ! check if acceptable substitue for safe owner address
			1,
			address(0),
			new bytes(0),
			gnosisFallbackLibrary,
			address(0),
			0,
			payable(address(0))
		);
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Internal
	/// ----------------------------------------------------------------------------------------

	/**
	 * calculate the counterfactual address of this account as it would be returned by createAccount()
	 */
	function getAddress(uint salt, uint[2] calldata owner) public view returns (address) {
		return
			Create2.computeAddress(
				bytes32(salt),
				keccak256(
					abi.encodePacked(
						type(ERC1967Proxy).creationCode,
						abi.encode(
							address(eip4337AccountSingleton),
							abi.encodeCall(eip4337AccountSingleton.initialize, (entryPoint, owner))
						)
					)
				)
			);
	}

	/// @dev modified from Aelin (https://github.com/AelinXYZ/aelin/blob/main/contracts/MinimalProxyFactory.sol)
	function _cloneAsMinimalProxy(
		address base,
		string memory _name
	) internal virtual returns (address payable clone) {
		bytes memory createData = abi.encodePacked(
			// constructor
			bytes10(0x3d602d80600a3d3981f3),
			// proxy code
			bytes10(0x363d3d373d3d3d363d73),
			base,
			bytes15(0x5af43d82803e903d91602b57fd5bf3)
		);

		bytes32 salt = keccak256(bytes(_name));

		assembly {
			clone := create2(
				0, // no value
				add(createData, 0x20), // data
				mload(createData),
				salt
			)
		}
		// if CREATE2 fails for some reason, address(0) is returned
		if (clone == address(0)) revert NullDeploy();
	}
}
