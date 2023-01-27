// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';

import {ForumSafe4337Module} from './ForumSafe4337Module.sol';

/// @notice Factory to deploy forum group.
contract ForumSafe4337Factory {
	/// ----------------------------------------------------------------------------------------
	/// Errors and Events
	/// ----------------------------------------------------------------------------------------

	event ForumSafeDeployed(
		ForumSafe4337Module indexed forumGroup,
		address indexed gnosisSafe,
		string name,
		string symbol,
		address[] voters,
		uint32[2] govSettings
	);

	event ForumSafeEnabled(
		ForumSafe4337Module indexed forumGroup,
		address indexed gnosisSafe,
		string name,
		string symbol,
		uint32[2] govSettings
	);

	error NullDeploy();

	error EnableModuleFailed();

	error DelegateCallOnly();

	/// ----------------------------------------------------------------------------------------
	/// Factory Storage
	/// ----------------------------------------------------------------------------------------

	GnosisSafeProxyFactory public gnosisSafeProxyFactory;

	// This address - stored for delegate call checks
	address public immutable forumFactory;
	// Template contract to use for new Gnosis safe proxies
	address public immutable gnosisSingleton;
	// Library to use for EIP1271 compatability
	address public immutable gnosisFallbackLibrary;
	// Library to use for all safe transaction executions
	address public immutable gnosisMultisendLibrary;
	// Template contract to use for new forum groups
	address public immutable forumSafeSingleton;
	// Forum initial extensions
	address public immutable entryPoint;
	address public immutable validaitonLogic;
	address public immutable fundraiseExtension;
	address public immutable withdrawalExtension;
	address public immutable pfpStaker;

	uint256 internal immutable BASIC_EXTENSION_COUNT = 5;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(
		address payable _forumSafeSingleton,
		address _gnosisSingleton,
		address _gnosisFallbackLibrary,
		address _gnosisMultisendLibrary,
		address _gnosisSafeProxyFactory,
		address _entryPoint,
		address _validaitonLogic,
		address _fundraiseExtension,
		address _withdrawalExtension,
		address _pfpStaker
	) {
		forumFactory = address(this);
		forumSafeSingleton = _forumSafeSingleton;
		gnosisSingleton = _gnosisSingleton;
		gnosisFallbackLibrary = _gnosisFallbackLibrary;
		gnosisMultisendLibrary = _gnosisMultisendLibrary;
		gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);
		entryPoint = _entryPoint;
		validaitonLogic = _validaitonLogic;
		fundraiseExtension = _fundraiseExtension;
		withdrawalExtension = _withdrawalExtension;
		pfpStaker = _pfpStaker;
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Deploys a new forum group and a new Gnosis safe
	 * @param _name Name of the forum group
	 * @param _symbol Symbol of the forum group
	 * @param _govSettings Array of governance settings
	 * @param _owners Array of initial owners on safe
	 * @param _customExtensions Array of custom extensions to add to the forum group
	 * @return forumModule The deployed forum group
	 * @return _safe The deployed Gnosis safe
	 */
	function deployForumSafe(
		string calldata _name,
		string calldata _symbol,
		uint32[2] calldata _govSettings,
		address[] calldata _owners,
		address[] calldata _customExtensions
	) external payable virtual returns (ForumSafe4337Module forumModule, GnosisSafe _safe) {
		// Deploy new safe but do not set it up yet
		_safe = GnosisSafe(
			payable(gnosisSafeProxyFactory.createProxy(gnosisSingleton, abi.encodePacked(_name)))
		);

		// Deploy new Forum group but do not set it up yet
		forumModule = ForumSafe4337Module(_cloneAsMinimalProxy(forumSafeSingleton, _name));

		{
			// Payload to enable the forum group module on the safe
			bytes memory _enableForumGroup = abi.encodeWithSignature(
				'enableModule(address)',
				address(forumModule)
			);
			// Generate payload for the safe to call enableModule on itself via multisend
			bytes memory _enableForumGroupMultisend = abi.encodePacked(
				Enum.Operation.Call,
				address(_safe),
				uint256(0),
				uint256(_enableForumGroup.length),
				bytes(_enableForumGroup)
			);
			// Encode data to be sent to multisend
			bytes memory _multisendAction = abi.encodeWithSignature(
				'multiSend(bytes)',
				_enableForumGroupMultisend
			);

			// Call setup on safe adding owners and enabling module
			_safe.setup(
				_owners,
				_owners.length,
				gnosisMultisendLibrary,
				_multisendAction,
				gnosisFallbackLibrary,
				address(0),
				0,
				payable(address(0))
			);
		}

		{
			// Create initialExtensions array
			address[] memory initialExtensions = _createInitialExtensions(_customExtensions);

			// Encode the init params, and set up the module
			forumModule.setUp(
				abi.encode(_name, _symbol, address(_safe), initialExtensions, _govSettings)
			);
		}

		emit ForumSafeDeployed(forumModule, address(_safe), _name, _symbol, _owners, _govSettings);
	}

	/**
	 * @dev Deploys a new Forum Safe Module and enables it on the calling safe
	 * @param _name Name of the new Forum Safe Module
	 * @param _symbol Symbol of the new Forum Safe Module
	 * @param _govSettings Array of governance settings for the new Forum Safe Module
	 * @return forumGroup The new Forum Safe Module
	 */
	function extendSafeWithForumModule(
		string calldata _name,
		string calldata _symbol,
		uint32[2] calldata _govSettings
	) external returns (ForumSafe4337Module forumGroup) {
		if (address(this) == forumFactory) revert DelegateCallOnly();

		// Deploy new Forum group
		forumGroup = ForumSafe4337Module(_cloneAsMinimalProxy(forumSafeSingleton, _name));

		// Create initialExtensions array - no custom extensions, therefore empty array
		address[] memory _initialExtensions = _createInitialExtensions(new address[](0));

		// Encode the init params, and set up the module
		forumGroup.setUp(
			abi.encode(_name, _symbol, address(this), _initialExtensions, _govSettings)
		);

		// Finally enable the module on the safe
		// The extendSafeWithForumModule() method is delegate called from the safe,
		// therefore the enableModule function called below updates the storage location of the safe
		(bool success, ) = (address(this)).call(
			abi.encodeWithSignature('enableModule(address)', address(forumGroup))
		);
		if (!success) revert EnableModuleFailed();

		emit ForumSafeEnabled(forumGroup, msg.sender, _name, _symbol, _govSettings);
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Internal
	/// ----------------------------------------------------------------------------------------

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

	/**
	 * @notice Creates the initial extensions array
	 * @param _customExtensions The initial extensions to add to the Forum
	 */
	function _createInitialExtensions(
		address[] memory _customExtensions
	) internal view returns (address[] memory initialExtensions) {
		// Create initialExtensions array of correct length. Basic Forum extensions + customExtensions
		initialExtensions = new address[](BASIC_EXTENSION_COUNT + _customExtensions.length);

		// Set the base Forum extensions
		(
			initialExtensions[0],
			initialExtensions[1],
			initialExtensions[2],
			initialExtensions[3],
			initialExtensions[4]
		) = (entryPoint, validaitonLogic, pfpStaker, fundraiseExtension, withdrawalExtension);

		// Set the custom extensions
		if (_customExtensions.length != 0) {
			// Cannot realistically overflow on human timescales
			unchecked {
				for (uint256 i; i < _customExtensions.length; ) {
					// +BASIC_EXTENSION_COUNT offsets the base Forum extensions
					initialExtensions[i + BASIC_EXTENSION_COUNT] = _customExtensions[i];

					++i;
				}
			}
		}
	}
}
