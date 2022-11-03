// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFieldSVGs {
	struct FieldData {
		string title;
		ICategories.FieldCategories fieldType;
		string svgString;
	}
}
