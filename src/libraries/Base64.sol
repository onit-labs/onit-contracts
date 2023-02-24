// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.13;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
/// @dev Modified to replace '/' with '_' and not pad with '=', with fixed length 43
library Base64 {
	bytes internal constant TABLE =
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		// Set length to format 32 byte hash without padding
		uint256 encodedLen = 43;

		// Add some extra buffer at the end
		bytes memory result = new bytes(encodedLen + 32);

		bytes memory table = TABLE;

		assembly {
			// set the actual output length
			mstore(result, encodedLen)

			// prepare the lookup table
			let tablePtr := add(table, 1)

			// input ptr
			let dataPtr := data
			let endPtr := add(dataPtr, mload(data))

			// result ptr, jump over length
			let resultPtr := add(result, 32)

			// run over the input, 3 bytes at a time
			for {

			} lt(dataPtr, endPtr) {

			} {
				// read 3 bytes
				dataPtr := add(dataPtr, 3)
				let input := mload(dataPtr)

				// write 4 characters
				mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
				resultPtr := add(resultPtr, 1)
				mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
				resultPtr := add(resultPtr, 1)
				mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
				resultPtr := add(resultPtr, 1)
				mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
				resultPtr := add(resultPtr, 1)
			}
		}

		return string(result);
	}
}
