// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

/* solhint-disable no-console */

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';

import {ForumGroupModule} from './ForumGroupModule.sol';
import {ERC4337Fallback} from './ERC4337Fallback.sol';

import 'forge-std/console.sol';

/// @notice Factory to deploy forum group.
contract ForumGroupFactory {
	/// ----------------------------------------------------------------------------------------
	/// Errors and Events
	/// ----------------------------------------------------------------------------------------

	event ForumSafeDeployed(ForumGroupModule indexed forumGroup, address indexed gnosisSafe);

	error NullDeploy();

	error EnableModuleFailed();

	error DelegateCallOnly();

	/// ----------------------------------------------------------------------------------------
	/// Factory Storage
	/// ----------------------------------------------------------------------------------------

	// This address - stored for delegate call checks
	address public immutable forumGroupFactory;

	// Template contract to use for new forum groups
	address public immutable forumGroupSingleton;

	// Template contract to use for new Gnosis safe proxies
	address public immutable gnosisSingleton;

	// Library to use for ERC1271 compatability
	address public immutable gnosisFallbackLibrary;

	// Library to use for all safe transaction executions
	address public immutable gnosisMultisendLibrary;

	// Factory to deploy new Gnosis safe proxies
	GnosisSafeProxyFactory public gnosisSafeProxyFactory;

	// Entry Point
	address public immutable entryPoint;

	// Address of deterministic deployment proxy, allowing address generation independent of deployer or nonce
	// https://github.com/Arachnid/deterministic-deployment-proxy
	address public constant DETERMINISTIC_DEPLOYMENT_PROXY =
		0x4e59b44847b379578588920cA78FbF26c0B4956C;

	// Data sent to the deterministic deployment proxy to deploy a new group module
	bytes private createProxyData;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(
		address payable _forumGroupSingleton,
		address _gnosisSingleton,
		address _gnosisFallbackLibrary,
		address _gnosisMultisendLibrary,
		address _gnosisSafeProxyFactory,
		address _entryPoint,
		address _ellipticValidator
	) {
		forumGroupFactory = address(this);
		forumGroupSingleton = _forumGroupSingleton;
		gnosisSingleton = _gnosisSingleton;
		gnosisFallbackLibrary = _gnosisFallbackLibrary;
		gnosisMultisendLibrary = _gnosisMultisendLibrary;
		gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);
		entryPoint = _entryPoint;

		// Data sent to the deterministic deployment proxy to deploy a new ERC4337 account
		createProxyData = abi.encodePacked(
			// constructor
			bytes10(0x3d602d80600a3d3981f3),
			// proxy code
			bytes10(0x363d3d373d3d3d363d73),
			_forumGroupSingleton,
			bytes15(0x5af43d82803e903d91602b57fd5bf3)
		);
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Deploys a new Forum group which manages a safe account
	 * @param _name Name of the forum group
	 * @param _ownersX Array of initial owners on safe
	 * @param _ownersY Array of initial owners on safe
	 * @return forumGroupSafe The deployed forum group
	 * @dev Returns an existing account address so that entryPoint.getSenderAddress() works even after account creation
	 */
	function deployForumGroup(
		string calldata _name,
		uint256 _voteThreshold,
		uint256[] calldata _ownersX,
		uint256[] calldata _ownersY
	) external payable virtual returns (address payable forumGroupSafe) {
		// ! Improve this salt - should be safely unique, and easily reusuable across chain
		bytes32 accountSalt = keccak256(abi.encode(_name));

		// address addr = getAddress(accountSalt);
		// uint codeSize = addr.code.length;
		// if (codeSize > 0) {
		// 	return payable(addr);
		// }

		// Deploy new safe with salt and init data
		forumGroupSafe = payable(
			gnosisSafeProxyFactory.createProxyWithNonce(
				gnosisSingleton,
				new bytes(0),
				uint256(accountSalt)
			)
		);

		// Deploy the module determinstically based on the salt (for now a hash of _name)
		(bool successCreate, bytes memory responseCreate) = DETERMINISTIC_DEPLOYMENT_PROXY.call{
			value: 0
		}(abi.encodePacked(accountSalt, createProxyData));

		// If successful, convert response to address to be returned
		ForumGroupModule _forumModule = ForumGroupModule(address(uint160(bytes20(responseCreate))));

		if (!successCreate || address(_forumModule) == address(0)) revert NullDeploy();

		// Deploy the fallback handler, setting the module in the constructor
		address _fallbackHandler = address(new ERC4337Fallback(address(_forumModule)));

		// Build multisend action to setup the module and enable modules on the safe
		bytes memory _multisendAction = buildMultisend(
			_forumModule,
			forumGroupSafe,
			_fallbackHandler,
			_voteThreshold,
			_ownersX,
			_ownersY
		);

		// Create a placeholder owner
		address[] memory _ownerPlaceholder = new address[](1);
		_ownerPlaceholder[0] = address(0xdead);

		GnosisSafe(forumGroupSafe).setup(
			_ownerPlaceholder,
			1,
			gnosisMultisendLibrary,
			_multisendAction,
			_fallbackHandler,
			address(0),
			0,
			payable(address(0))
		);

		// bytes memory _setupSafe = abi.encodeCall(
		// 	GnosisSafe.setup,
		// 	(
		// 		_ownerPlaceholder,
		// 		1,
		// 		gnosisMultisendLibrary,
		// 		_multisendAction,
		// 		_fallbackHandler,
		// 		address(0),
		// 		0,
		// 		payable(address(0))
		// 	)
		// );

		// // Deploy new safe with salt and init data
		// forumGroupSafe = payable(
		// 	gnosisSafeProxyFactory.createProxyWithNonce(
		// 		gnosisSingleton,
		// 		_setupSafe,
		// 		uint256(accountSalt)
		// 	)
		// );

		emit ForumSafeDeployed(_forumModule, forumGroupSafe);
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Internal
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Get the address of an account that would be returned by createAccount()
	 * @dev Salt should be keccak256(abi.encode(otherSalt, owner)) where otherSalt is some bytes32
	 */
	function getAddress(bytes32 salt) public returns (address clone) {
		return
			address(
				gnosisSafeProxyFactory.calculateCreateProxyWithNonceAddress(
					gnosisSingleton,
					new bytes(0), // ! if deployed with initdata, this needs updated
					uint256(salt)
				)
			);
		// return
		// 	address(
		// 		bytes20(
		// 			keccak256(
		// 				abi.encodePacked(
		// 					bytes1(0xff),
		// 					DETERMINISTIC_DEPLOYMENT_PROXY,
		// 					salt,
		// 					keccak256(createProxyData)
		// 				)
		// 			) << 96
		// 		)
		// 	);
	}

	function buildMultisend(
		ForumGroupModule _forumModule,
		address _forumGroupSafe,
		address _fallbackHandler,
		uint256 _voteThreshold,
		uint256[] memory _ownersX,
		uint256[] memory _ownersY
	) internal view returns (bytes memory _multisendAction) {
		// Payload to enable the fallback handler on the safe
		bytes memory _enableFallbackHandler = abi.encodeWithSignature(
			'enableModule(address)',
			_fallbackHandler
		);

		// Generate payload for the safe to call enableModule on itself via multisend
		bytes memory _enableFallbackHandlerMultisend = abi.encodePacked(
			Enum.Operation.Call,
			_forumGroupSafe,
			uint256(0),
			uint256(_enableFallbackHandler.length),
			bytes(_enableFallbackHandler)
		);
		// Payload to enable the forum entrypoint as a module on the safe
		bytes memory _enableEntryPoint = abi.encodeWithSignature(
			'enableModule(address)',
			entryPoint
		);

		// Generate payload for the safe to call enableModule on itself via multisend
		bytes memory _enableEntrypointMultisend = abi.encodePacked(
			Enum.Operation.Call,
			_forumGroupSafe,
			uint256(0),
			uint256(_enableEntryPoint.length),
			bytes(_enableEntryPoint)
		);

		// Encode call to setup the module storage
		bytes memory _setupModuleStorage = abi.encodeCall(
			_forumModule.setUp,
			(_fallbackHandler, _forumGroupSafe, _voteThreshold, _ownersX, _ownersY)
		);

		// Generate payload for the safe to call setup on the module via multisend
		// Must be call as we want to set the storage on the module
		bytes memory _setupModuleStorageMultisend = abi.encodePacked(
			Enum.Operation.Call,
			_forumModule,
			uint256(0),
			uint256(_setupModuleStorage.length),
			_setupModuleStorage
		);

		// Encode data to be sent to multisend
		_multisendAction = abi.encodeWithSignature(
			'multiSend(bytes)',
			abi.encodePacked(
				_setupModuleStorageMultisend,
				_enableEntrypointMultisend,
				_enableFallbackHandlerMultisend
			)
		);
	}
}
