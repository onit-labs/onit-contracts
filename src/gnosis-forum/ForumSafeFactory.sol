// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.15;

//import 'forge-std/console.sol';

// ! fix remappings failings with hardhat
import {GnosisSafe} from '@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol';
import {GnosisSafeProxyFactory} from '@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol';

import {Owned} from '../utils/Owned.sol';

import {ForumSafeModule} from './ForumSafeModule.sol';

/// @notice Factory to deploy forum group.
contract ForumSafeFactory is Owned {
	/// ----------------------------------------------------------------------------------------
	/// Errors and Events
	/// ----------------------------------------------------------------------------------------

	event GroupDeployed(
		ForumSafeModule indexed forumGroup,
		string name,
		string symbol,
		address[] voters,
		uint32[4] govSettings
	);

	error NullDeploy();

	error MemberLimitExceeded();

	/// ----------------------------------------------------------------------------------------
	/// Factory Storage
	/// ----------------------------------------------------------------------------------------

	GnosisSafeProxyFactory public gnosisSafeProxyFactory;
	// ModuleProxyFactory moduleProxyFactory;

	// Template contract to use for new Gnosis safe proxies
	address public immutable gnosisSingleton;
	// Library to use for EIP1271 compatability
	address public immutable gnosisFallbackLibrary;
	// Library to use for all safe transaction executions
	address public immutable gnosisMultisendLibrary;

	address public forumSafeSingleton;
	address public fundraiseExtension;
	address public withdrawalExtension;
	address public pfpStaker;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(
		address deployer,
		address payable _forumSafeSingleton,
		address _gnosisSingleton,
		address _gnosisFallbackLibrary,
		address _gnosisMultisendLibrary,
		address _gnosisSafeProxyFactory
	) Owned(deployer) {
		forumSafeSingleton = _forumSafeSingleton;
		gnosisSingleton = _gnosisSingleton;
		gnosisFallbackLibrary = _gnosisFallbackLibrary;
		gnosisMultisendLibrary = _gnosisMultisendLibrary;
		gnosisSafeProxyFactory = GnosisSafeProxyFactory(_gnosisSafeProxyFactory);
		// _moduleProxyFactory
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	function setForumSafeSingleton(address _forumSafeSingleton) external onlyOwner {
		forumSafeSingleton = _forumSafeSingleton;
	}

	function setPfpStaker(address _pfpStaker) external onlyOwner {
		pfpStaker = _pfpStaker;
	}

	function setFundraiseExtension(address _fundraiseExtension) external onlyOwner {
		fundraiseExtension = _fundraiseExtension;
	}

	function setWithdrawalExtension(address _withdrawalExtension) external onlyOwner {
		withdrawalExtension = _withdrawalExtension;
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	function deployForumSafe(
		string calldata name_,
		string calldata symbol_,
		uint32[4] calldata govSettings_,
		address[] calldata voters_,
		address[] calldata customExtensions_
	) public payable virtual returns (ForumSafeModule forumGroup, GnosisSafe _safe) {
		if (voters_.length > 100) revert MemberLimitExceeded();

		// Deploy new safe but do not set it up yet
		_safe = GnosisSafe(
			payable(
				gnosisSafeProxyFactory.createProxy(
					gnosisSingleton,
					abi.encodePacked(name_)
					//abi.encodePacked(_moloch, _saltNonce)
				)
			)
		);

		// Deploy new Forum group but do not set it up yet
		forumGroup = ForumSafeModule(_cloneAsMinimalProxy(forumSafeSingleton, name_));

		{
			// Generate delegate calls so the safe calls enableModule on itself during setup
			bytes memory _enableForumGroup = abi.encodeWithSignature(
				'enableModule(address)',
				address(forumGroup)
			);
			bytes memory _enableForumGroupMultisend = abi.encodePacked(
				uint8(0),
				address(_safe),
				uint256(0),
				uint256(_enableForumGroup.length),
				bytes(_enableForumGroup)
			);
			bytes memory _multisendAction = abi.encodeWithSignature(
				'multiSend(bytes)',
				_enableForumGroupMultisend
			);

			// Workaround for solidity dynamic memory array
			address[] memory _owners = new address[](1);
			_owners[0] = address(forumGroup);

			// Call setup on safe to enable our new module and set the module as the only signer
			_safe.setup(
				_owners,
				1,
				gnosisMultisendLibrary,
				_multisendAction,
				gnosisFallbackLibrary,
				address(0),
				0,
				payable(address(0))
			);
		}

		{
			// Create initialExtensions array of correct length. 2 Forum set extensions + customExtensions
			address[] memory initialExtensions = new address[](2 + customExtensions_.length);

			// Set the base Forum extensions // todo add withdrawal extension as default
			(initialExtensions[0], initialExtensions[1]) = (pfpStaker, fundraiseExtension);

			// Set the custom extensions
			if (customExtensions_.length != 0) {
				// Cannot realistically overflow on human timescales
				unchecked {
					for (uint256 i; i < customExtensions_.length; ) {
						// +2 offsets the base Forum extensions
						initialExtensions[i + 2] = customExtensions_[i];

						++i;
					}
				}
			}

			//!!!!! remove hardcoding after testing (used to speed up compile without needing via-ir)
			bytes memory init = abi.encode(
				'test',
				symbol_,
				address(_safe),
				voters_,
				initialExtensions,
				govSettings_
			);

			forumGroup.setUp(init);
		}
		emit GroupDeployed(forumGroup, name_, symbol_, voters_, govSettings_);
	}

	//  function extendSafeWithForumModule()

	/// @dev modified from Aelin (https://github.com/AelinXYZ/aelin/blob/main/contracts/MinimalProxyFactory.sol)
	function _cloneAsMinimalProxy(
		address base,
		string memory name_
	) internal virtual returns (address payable clone) {
		bytes memory createData = abi.encodePacked(
			// constructor
			bytes10(0x3d602d80600a3d3981f3),
			// proxy code
			bytes10(0x363d3d373d3d3d363d73),
			base,
			bytes15(0x5af43d82803e903d91602b57fd5bf3)
		);

		bytes32 salt = keccak256(bytes(name_));

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
