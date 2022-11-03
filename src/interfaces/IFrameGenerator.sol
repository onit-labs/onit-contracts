// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IFrameSVGs.sol';

/// @dev Generate Frame SVG
interface IFrameGenerator {
	struct FrameSVGs {
		IFrameSVGs frameSVGs1;
		IFrameSVGs frameSVGs2;
	}

	/// @param Frame uint representing Frame selection
	/// @return FrameData containing svg snippet and Frame title and Frame type
	function generateFrame(uint16 Frame) external view returns (IFrameSVGs.FrameData memory);
}
