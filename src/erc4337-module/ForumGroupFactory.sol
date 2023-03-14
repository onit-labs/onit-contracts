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

	GnosisSafeProxyFactory public gnosisSafeProxyFactory;

	// This address - stored for delegate call checks
	address public immutable forumGroupFactory;

	// Template contract to use for new Gnosis safe proxies
	address public immutable gnosisSingleton;

	// Library to use for ERC1271 compatability
	address public immutable gnosisFallbackLibrary;

	// Library to use for all safe transaction executions
	address public immutable gnosisMultisendLibrary;

	// Template contract to use for new forum groups
	address public immutable forumGroupSingleton;

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

		// Deploy the module determinstically based on the salt (for now a hash of _name)
		(bool successCreate, bytes memory responseCreate) = DETERMINISTIC_DEPLOYMENT_PROXY.call{
			value: 0
		}(abi.encodePacked(accountSalt, createProxyData));

		// If successful, convert response to address to be returned
		ForumGroupModule _forumModule = ForumGroupModule(address(uint160(bytes20(responseCreate))));

		if (!successCreate || address(_forumModule) == address(0)) revert NullDeploy();

		// Create array of owners
		address[] memory _ownerPlaceholder = new address[](1);
		_ownerPlaceholder[0] = address(0xdead);

		// Create multicall to
		// 1) setup the module

		address _fallbackHandler = address(new ERC4337Fallback(address(_forumModule)));

		bytes memory _multisendAction = buildMultisend(
			_forumModule,
			_fallbackHandler,
			_voteThreshold,
			_ownersX,
			_ownersY
		);

		bytes memory _setupSafe = abi.encodeCall(
			GnosisSafe.setup,
			(
				_ownerPlaceholder,
				1,
				gnosisMultisendLibrary,
				_multisendAction,
				_fallbackHandler,
				address(0),
				0,
				payable(address(0))
			)
		);

		// Deploy new safe with salt and init data
		forumGroupSafe = payable(
			gnosisSafeProxyFactory.createProxyWithNonce(
				gnosisSingleton,
				_setupSafe,
				uint256(accountSalt)
			)
		);

		emit ForumSafeDeployed(_forumModule, forumGroupSafe);
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Internal
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Get the address of an account that would be returned by createAccount()
	 * @dev Salt should be keccak256(abi.encode(otherSalt, owner)) where otherSalt is some bytes32
	 */
	function getAddress(bytes32 salt) public view returns (address clone) {
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

	function buildMultisend(
		ForumGroupModule _forumModule,
		address _fallbackHandler,
		uint256 _voteThreshold,
		uint256[] memory _ownersX,
		uint256[] memory _ownersY
	) internal returns (bytes memory _multisendAction) {
		// Encode call to setup safe modules
		bytes memory _setupSafeModules = abi.encodeCall(_forumModule.setUpModules, ());

		// Generate payload for the safe to delegatecall setup on the module via multisend
		bytes memory _setupSafeModulesMultisend = abi.encodePacked(
			Enum.Operation.DelegateCall,
			_forumModule,
			uint256(0),
			uint256(_setupSafeModules.length),
			_setupSafeModules
		);

		// Encode call to setup the module storage
		bytes memory _setupModuleStorage = abi.encodeCall(
			_forumModule.setUp,
			(_fallbackHandler, _voteThreshold, _ownersX, _ownersY)
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
			abi.encodePacked(_setupModuleStorageMultisend)
		);
	}
}
