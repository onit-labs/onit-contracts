// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

interface IEllipticCurveValidator {
	function validateSignature(
		bytes32 message,
		uint256[2] memory signature,
		uint256[2] memory publicKey
	) external view returns (bool);
}
