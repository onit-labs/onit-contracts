// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

interface IPfpAccessControl {
	function mintRestriction(
		address _to,
		uint256 _tokenId,
		uint256 _amount,
		bytes memory _data
	) external view returns (bool);

	function burnRestriction(
		address _from,
		uint256 _tokenId,
		uint256 _amount
	) external view returns (bool);

	function safeTransferFromRestriction(
		address _from,
		address _to,
		uint256 _tokenId,
		uint256 _amount,
		bytes memory _data
	) external view returns (bool);
}
