// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/IFieldGenerator.sol';
import '../interfaces/IFieldSVGs.sol';

import '../utils/Owned.sol';

/// @dev Test Field Generator with less SVGs / less deploy overhead
contract TestFieldGenerator is Owned, IFieldGenerator {
	using Strings for uint16;

	mapping(uint24 => Color) public _colors;

	struct TestFieldSVGs {
		IFieldSVGs fieldSVGs1;
		IFieldSVGs fieldSVGs3;
		IFieldSVGs fieldSVGs7;
		IFieldSVGs fieldSVGs23;
	}

	IFieldSVGs immutable fieldSVGs1;
	IFieldSVGs immutable fieldSVGs3;
	IFieldSVGs immutable fieldSVGs7;
	IFieldSVGs immutable fieldSVGs23;

	constructor(address deployer, TestFieldSVGs memory svgs) Owned(deployer) {
		fieldSVGs1 = svgs.fieldSVGs1;
		fieldSVGs3 = svgs.fieldSVGs3;
		fieldSVGs7 = svgs.fieldSVGs7;
		fieldSVGs23 = svgs.fieldSVGs23;
	}

	// Extended color list causes error deploying due to gas limit. Here we can add further colors
	function addColors(uint24[] memory __colors, string[] memory titles) external {
		uint256 colorsLength = __colors.length;
		require(colorsLength == titles.length, 'invalid array lengths');
		for (uint256 i = 0; i < colorsLength; i++) {
			require(__colors[i] != 0, 'FieldGenerator: colors cannot be 0');
			_colors[__colors[i]] = Color({title: titles[i], exists: true});
		}
		emit ColorsAdded(__colors[0], __colors[colorsLength - 1], colorsLength);
	}

	function colorExists(uint24 color) public view override returns (bool) {
		return _colors[color].exists;
	}

	function colorTitle(uint24 color) public view override returns (string memory) {
		return _colors[color].title;
	}

	function callFieldSVGs(
		IFieldSVGs target,
		uint16 field,
		uint24[4] memory colors
	) internal view returns (IFieldSVGs.FieldData memory) {
		bytes memory functionSelector = abi.encodePacked(
			'field_',
			uint16(field).toString(),
			'(uint24[4])'
		);

		bool success;
		bytes memory result;
		(success, result) = address(target).staticcall(
			abi.encodeWithSelector(bytes4(keccak256(functionSelector)), colors)
		);

		return abi.decode(result, (IFieldSVGs.FieldData));
	}

	function generateField(uint16 field, uint24[4] memory colors)
		external
		view
		override
		returns (IFieldSVGs.FieldData memory)
	{
		if (field <= 28) {
			return callFieldSVGs(fieldSVGs1, field, colors);
		}

		if (field <= 66) {
			return callFieldSVGs(fieldSVGs3, field, colors);
		}

		if (field <= 150) {
			return callFieldSVGs(fieldSVGs7, field, colors);
		}

		if (field <= 298) {
			return callFieldSVGs(fieldSVGs23, field, colors);
		}
		revert('invalid field selection');
	}
}
