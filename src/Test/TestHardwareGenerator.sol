// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/IHardwareSVGs.sol';
import '../interfaces/IHardwareGenerator.sol';

/// @dev Generate Hardware SVG and properties
/// @author modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts)
contract TestHardwareGenerator is IHardwareGenerator {
	using Strings for uint16;

	// Transforms from top left to bottom right
	string[9] transforms = [
		'<g transform="matrix(0.5 0 0 0.5 30 36)">',
		'<g transform="matrix(0.5 0 0 0.5 55 36)">',
		'<g transform="matrix(0.5 0 0 0.5 80 36)">',
		'<g transform="matrix(0.5 0 0 0.5 30 66)">',
		'<g>',
		'<g transform="matrix(0.5 0 0 0.5 80 66)">',
		'<g transform="matrix(0.45 0 0 0.45 38.5 99.6)">',
		'<g transform="matrix(0.5 0 0 0.5 55 96)">',
		'<g transform="matrix(0.45 0 0 0.45 82.5 99.6)">'
	];

	using Strings for uint16;

	IHardwareSVGs immutable hardwareSVGs1;
	IHardwareSVGs immutable hardwareSVGs29;

	struct TestHardwardSVGs {
		IHardwareSVGs hardwareSVGs1;
		IHardwareSVGs hardwareSVGs29;
	}

	constructor(TestHardwardSVGs memory svgs) {
		hardwareSVGs1 = svgs.hardwareSVGs1;
		hardwareSVGs29 = svgs.hardwareSVGs29;
	}

	function callHardwareSVGs(IHardwareSVGs target, uint16 hardware)
		internal
		view
		returns (IHardwareSVGs.HardwareData memory)
	{
		bytes memory functionSelector = abi.encodePacked(
			'hardware_',
			uint16(hardware).toString(),
			'()'
		);

		bool success;
		bytes memory result;
		(success, result) = address(target).staticcall(
			abi.encodeWithSelector(bytes4(keccak256(functionSelector)))
		);

		return abi.decode(result, (IHardwareSVGs.HardwareData));
	}

	function generateHardware(uint16[9] calldata hardware)
		external
		view
		returns (IHardwareSVGs.HardwareData memory)
	{
		string memory title;
		ICategories.HardwareCategories hardwareType;
		string memory transformedHardware;

		uint256 count;

		for (uint16 i; i < 9; ) {
			if (hardware[i] != 999) {
				IHardwareSVGs.HardwareData memory tmp = generateHardwareItem(hardware[i]);

				if (bytes(title).length == 0) title = tmp.title;
				else title = string(abi.encodePacked(title, ' + ', tmp.title));

				++count;
				hardwareType = tmp.hardwareType;

				transformedHardware = string(
					abi.encodePacked(transformedHardware, transforms[i], tmp.svgString, '</g>')
				);
			}
			unchecked {
				++i;
			}
		}

		if (count == 2) {
			hardwareType = ICategories.HardwareCategories.DOUBLE;
		}
		if (count > 2) {
			hardwareType = ICategories.HardwareCategories.MULTI;
		}

		return (IHardwareSVGs.HardwareData(title, hardwareType, transformedHardware));
	}

	function generateHardwareItem(uint16 hardware)
		internal
		view
		returns (IHardwareSVGs.HardwareData memory)
	{
		if (hardware <= 5) {
			return callHardwareSVGs(hardwareSVGs1, hardware);
		}

		if (hardware <= 97) {
			return callHardwareSVGs(hardwareSVGs29, hardware);
		}

		revert('invalid hardware selection');
	}
}
