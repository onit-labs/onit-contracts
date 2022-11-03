// // SPDX-License-Identifier: The Unlicense
// pragma solidity ^0.8.13;

// import '../ShieldManager/src/ShieldManager.sol';
// import '../interfaces/IAccessManager.sol';
// import '../interfaces/IFieldSVGs.sol';
// import '../interfaces/IHardwareSVGs.sol';
// import '../interfaces/IFrameSVGs.sol';

// /// @dev Generate Customizable Shields
// contract ShieldsTest is ShieldManager {
// 	constructor(
// 		string memory name_,
// 		string memory symbol_,
// 		IEmblemWeaver _emblemWeaver,
// 		IAccessManager _accessManager
// 	) ShieldManager(name_, symbol_, _emblemWeaver, _accessManager) {}

// 	function getNextId() external view returns (uint256) {
// 		return currentId;
// 	}

// 	function setNextId(uint256 nextId) external {
// 		nextId = currentId;
// 	}
// }
