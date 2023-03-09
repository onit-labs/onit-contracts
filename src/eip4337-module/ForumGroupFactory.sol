// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';

import {ForumGroupModule} from './ForumGroupModule.sol';

/// @notice Factory to deploy forum group.
contract ForumGroupFactory {
	/// ----------------------------------------------------------------------------------------
	/// Errors and Events
	/// ----------------------------------------------------------------------------------------

	event ForumSafeDeployed(
		ForumGroupModule indexed forumGroup,
		address indexed gnosisSafe,
		string name
	);

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

	// Library to use for EIP1271 compatability
	address public immutable gnosisFallbackLibrary;

	// Library to use for all safe transaction executions
	address public immutable gnosisMultisendLibrary;

	// Template contract to use for new forum groups
	address public immutable forumGroupSingleton;

	// Forum initial extensions
	address public immutable entryPoint;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(
		address payable _forumGroupSingleton,
		address _gnosisSingleton,
		address _gnosisFallbackLibrary,
		address _gnosisMultisendLibrary,
		address _gnosisSafeProxyFactory,
		address _entryPoint
	) {
		forumGroupFactory = address(this);
		forumGroupSingleton = _forumGroupSingleton;
		gnosisSingleton = _gnosisSingleton;
		gnosisFallbackLibrary = _gnosisFallbackLibrary;
		gnosisMultisendLibrary = _gnosisMultisendLibrary;
		gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);
		entryPoint = _entryPoint;
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	/**
	 * @notice Deploys a new Forum group which manages a safe account
	 * @param _name Name of the forum group
	 * @param _ownersX Array of initial owners on safe
	 * @param _ownersY Array of initial owners on safe
	 * @return forumModule The deployed forum group
	 * @return _safe The deployed Gnosis safe
	 */
	function deployForumGroup(
		string calldata _name,
		uint256 _voteThreshold,
		uint256[] calldata _ownersX,
		uint256[] calldata _ownersY
	) external payable virtual returns (ForumGroupModule forumModule, GnosisSafe _safe) {
		// Deploy new safe but do not set it up yet
		_safe = GnosisSafe(
			payable(gnosisSafeProxyFactory.createProxy(gnosisSingleton, abi.encodePacked(_name)))
		);

		// Deploy new Forum group but do not set it up yet
		forumModule = ForumGroupModule(_cloneAsMinimalProxy(forumGroupSingleton, _name));

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

			// Create array of owners
			address[] memory ownerPlaceholder = new address[](1);
			ownerPlaceholder[0] = address(0xdead);

			// Call setup on safe adding owners and enabling module
			_safe.setup(
				ownerPlaceholder,
				1,
				gnosisMultisendLibrary,
				_multisendAction,
				gnosisFallbackLibrary,
				address(0),
				0,
				payable(address(0))
			);
		}

		// Set up the module
		forumModule.setUp(address(_safe), _voteThreshold, _ownersX, _ownersY);

		emit ForumSafeDeployed(forumModule, address(_safe), _name);
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
}
