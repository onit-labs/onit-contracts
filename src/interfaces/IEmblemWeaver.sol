// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IShieldManager.sol';
import './IFrameGenerator.sol';
import './IFieldGenerator.sol';
import './IHardwareGenerator.sol';

/// @dev Generate Customizable Shields
interface IEmblemWeaver {
	function fieldGenerator() external returns (IFieldGenerator);

	function hardwareGenerator() external returns (IHardwareGenerator);

	function frameGenerator() external returns (IFrameGenerator);

	function generateShieldPass() external pure returns (string memory);

	function generateShieldURI(IShieldManager.Shield memory shield)
		external
		view
		returns (string memory);
}
