// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

/* solhint-disable no-console */

import {GnosisSafe, Enum} from '@gnosis/GnosisSafe.sol';
import {GnosisSafeProxyFactory} from '@gnosis/proxies/GnosisSafeProxyFactory.sol';

import {ForumGroupModule} from './ForumGroupModule.sol';

import 'forge-std/console.sol';

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

	// Library to use for ERC1271 compatability
	address public immutable gnosisFallbackLibrary;

	// Library to use for all safe transaction executions
	address public immutable gnosisMultisendLibrary;

	// Template contract to use for new forum groups
	address public immutable forumGroupSingleton;

	// Forum initial extensions
	address public immutable entryPoint;

	// Elliptic curve validator contract used for signing
	address public immutable ellipticValidator;

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
		ellipticValidator = _ellipticValidator;
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
		// Deploy new Forum group module but do not set it up yet
		forumModule = new ForumGroupModule(ellipticValidator, entryPoint);

		bytes memory setup4337Modules = abi.encodeCall(
			ForumGroupModule.setUp,
			(forumModule, _voteThreshold, _ownersX, _ownersY)
		);

		// Create array of owners
		address[] memory ownerPlaceholder = new address[](1);
		ownerPlaceholder[0] = address(0xdead);

		bytes memory create = abi.encodeCall(
			GnosisSafe.setup,
			(
				ownerPlaceholder,
				1,
				address(forumModule),
				setup4337Modules,
				forumModule.erc4337Fallback(),
				address(0),
				0,
				payable(address(0))
			)
		);

		// Deploy new safe but do not set it up yet
		_safe = GnosisSafe(
			payable(
				gnosisSafeProxyFactory.createProxyWithNonce(gnosisSingleton, create, uint256(1))
			)
		);

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
