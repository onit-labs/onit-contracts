// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './ICategories.sol';

interface IFrameSVGs {
	struct FrameData {
		string title;
		ICategories.FrameCategories frameType;
		string svgString;
	}
}
