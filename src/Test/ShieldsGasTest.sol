// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.13;

import '../ShieldManager/src/ShieldManager.sol';

/// @dev Generate Customizable Shields
contract ShieldsGasTest {
	ShieldManager public immutable shields;

	constructor(ShieldManager _shields) {
		shields = _shields;
	}

	function gasSnapshotTokenURI(uint256 tokenId) public view returns (uint256) {
		uint256 gasBefore = gasleft();
		shields.tokenURI(tokenId);
		return gasBefore - gasleft();
	}
}
