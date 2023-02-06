// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

/* solhint-disable avoid-low-level-calls */

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';

import {EIP4337Account, IEntryPoint} from './EIP4337Account.sol';

import 'forge-std/console.sol';

/// @notice Factory to deploy an ERC4337 Account
/// @author ForumDAOs (https://forumdaos.com)
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

	error AccountInitFailed();

	/// ----------------------------------------------------------------------------------------
	/// Factory Storage
	/// ----------------------------------------------------------------------------------------

	// Template contract to use for new individual ERC4337 accounts
	EIP4337Account public immutable eip4337AccountSingleton;

	// Entry point used for ERC4337 accounts
	IEntryPoint public immutable entryPoint;

	// Fallback handler for Gnosis Safe
	address public immutable gnosisFallbackLibrary;

	// Address of deterministic deployment proxy, allowing address generation independent of deployer or nonce
	// https://github.com/Arachnid/deterministic-deployment-proxy
	address public constant DETERMINISTIC_DEPLOYMENT_PROXY =
		0x4e59b44847b379578588920cA78FbF26c0B4956C;

	bytes private createProxyData;

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

		// Data sent to the deterministic deployment proxy to deploy a new ERC4337 account
		createProxyData = abi.encodePacked(
			// constructor
			bytes10(0x3d602d80600a3d3981f3),
			// proxy code
			bytes10(0x363d3d373d3d3d363d73),
			eip4337AccountSingleton,
			bytes15(0x5af43d82803e903d91602b57fd5bf3)
		);
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Deploys a new ERC4337 account built on a Gnosis safe
	 * @param salt Salt for deterministic address generation
	 * @param owner Public key for secp256r1 signer
	 * @return account The deployed account
	 * @dev This method returns an existing account address so that entryPoint.getSenderAddress() would work even after account creation
	 */
	function createAccount(
		bytes32 salt,
		uint[2] calldata owner
	) external payable virtual returns (address payable account) {
		address addr = getAddress(salt, owner);
		uint codeSize = addr.code.length;
		if (codeSize > 0) {
			return payable(addr);
		}

		(bool successCreate, bytes memory responseCreate) = DETERMINISTIC_DEPLOYMENT_PROXY.call{
			value: 0
		}(abi.encodePacked(salt, createProxyData));

		if (!successCreate) revert NullDeploy();

		account = payable(address(uint160(bytes20(responseCreate))));

		(bool successInit, ) = account.call(
			abi.encodeCall(
				eip4337AccountSingleton.initialize,
				abi.encode(entryPoint, owner, gnosisFallbackLibrary)
			)
		);

		if (!successInit || account == address(0)) revert AccountInitFailed();
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Internal
	/// ----------------------------------------------------------------------------------------

	/**
	 * calculate the counterfactual address of this account as it would be returned by createAccount()
	 */
	// ! integrate owner here also
	function getAddress(bytes32 salt, uint[2] calldata owner) public view returns (address clone) {
		return
			address(
				bytes20(
					keccak256(
						abi.encodePacked(
							bytes1(0xff),
							DETERMINISTIC_DEPLOYMENT_PROXY,
							salt,
							keccak256(createProxyData)
						)
					) << 96
				)
			);
	}
}
