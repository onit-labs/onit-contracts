// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {Owned} from '../utils/Owned.sol';

import {ForumGroup, Multicall} from './ForumGroup.sol';

/// @notice Factory to deploy forum group.
contract ForumFactory is Multicall, Owned {
	/// ----------------------------------------------------------------------------------------
	/// Errors and Events
	/// ----------------------------------------------------------------------------------------

	event GroupDeployed(
		ForumGroup indexed forumGroup,
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

	address public forumMaster;
	address public fundraiseExtension;
	address public commissionManager;
	address public pfpStaker;

	/// ----------------------------------------------------------------------------------------
	/// Constructor
	/// ----------------------------------------------------------------------------------------

	constructor(address deployer) Owned(deployer) {}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	function setForumMaster(address forumMaster_) external onlyOwner {
		forumMaster = forumMaster_;
	}

	function setPfpStaker(address pfpStaker_) external onlyOwner {
		pfpStaker = pfpStaker_;
	}

	function setFundraiseExtension(address fundraiseExtension_) external onlyOwner {
		fundraiseExtension = fundraiseExtension_;
	}

	function setCommissionManager(address commissionManager_) external onlyOwner {
		commissionManager = commissionManager_;
	}

	/// ----------------------------------------------------------------------------------------
	/// Factory Logic
	/// ----------------------------------------------------------------------------------------

	function deployGroup(
		string calldata name_,
		string calldata symbol_,
		uint32[4] calldata govSettings_,
		address[] calldata voters_,
		address[] calldata customExtensions_
	) public payable virtual returns (ForumGroup forumGroup) {
		if (voters_.length > 100) revert MemberLimitExceeded();

		forumGroup = ForumGroup(_cloneAsMinimalProxy(forumMaster, name_));

		// Create initialExtensions array of correct length. 3 Forum set extensions + customExtensions
		address[] memory initialExtensions = new address[](3 + customExtensions_.length);

		// Set the base Forum extensions
		(initialExtensions[0], initialExtensions[1], initialExtensions[2]) = (
			pfpStaker,
			commissionManager,
			fundraiseExtension
		);

		// Set the custom extensions
		if (customExtensions_.length != 0) {
			// Cannot realistically overflow on human timescales
			unchecked {
				for (uint256 i = 0; i < customExtensions_.length; i++) {
					// +3 offsets the base Forum extensions
					initialExtensions[i + 3] = customExtensions_[i];
				}
			}
		}

		forumGroup.init{value: msg.value}(name_, symbol_, voters_, initialExtensions, govSettings_);

		emit GroupDeployed(forumGroup, name_, symbol_, voters_, govSettings_);
	}

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
