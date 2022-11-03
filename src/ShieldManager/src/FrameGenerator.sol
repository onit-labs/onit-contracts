// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../../interfaces/IFrameSVGs.sol';
import '../../interfaces/IFrameGenerator.sol';

/// @dev Generate Frame SVG and properties
/// @author modified from Area-Technology (https://github.com/Area-Technology/shields-contracts/tree/main/contracts)
contract FrameGenerator is IFrameGenerator {
	using Strings for uint16;

	IFrameSVGs immutable frameSVGs1;
	IFrameSVGs immutable frameSVGs2;

	constructor(FrameSVGs memory svgs) {
		frameSVGs1 = svgs.frameSVGs1;
		frameSVGs2 = svgs.frameSVGs2;
	}

	function generateFrame(uint16 frame)
		external
		view
		override
		returns (IFrameSVGs.FrameData memory)
	{
		if (frame <= 3) {
			return callFrameSVGs(frameSVGs1, frame);
		}

		if (frame <= 5) {
			return callFrameSVGs(frameSVGs2, frame);
		}

		revert('invalid frame selection');
	}

	function callFrameSVGs(IFrameSVGs target, uint16 frame)
		internal
		view
		returns (IFrameSVGs.FrameData memory)
	{
		bytes memory functionSelector = abi.encodePacked('frame_', uint16(frame).toString(), '()');

		bool success;
		bytes memory result;
		(success, result) = address(target).staticcall(
			abi.encodeWithSelector(bytes4(keccak256(functionSelector)))
		);

		return abi.decode(result, (IFrameSVGs.FrameData));
	}
}
