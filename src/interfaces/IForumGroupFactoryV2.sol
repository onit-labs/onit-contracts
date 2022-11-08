// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

import {IForumGroup} from './IForumGroup.sol';

/// @notice Forum Factory V2 Interface.
interface IForumGroupFactoryV2 {
	function deployGroup(
		string calldata name_,
		string calldata symbol_,
		address[] calldata voters_,
		uint32[4] calldata govSettings_,
		address[] calldata customExtensions_
	) external payable returns (IForumGroup);
}
