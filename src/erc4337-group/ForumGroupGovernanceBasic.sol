// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/// @notice Minimal ERC1155 like token store for groups

abstract contract ForumGroupGovernanceBasic {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	// event TransferSingle(
	// 	address indexed operator,
	// 	address indexed from,
	// 	bytes32 indexed to,
	// 	uint256 id,
	// 	uint256 amount
	// );

	// event TransferBatch(
	// 	address indexed operator,
	// 	bytes32 indexed from,
	// 	address indexed to,
	// 	uint256[] ids,
	// 	uint256[] amounts
	// );

	error InvalidNonce();

	/// ----------------------------------------------------------------------------------------
	///							TOKEN STORAGE
	/// ----------------------------------------------------------------------------------------

	// Token representing voting share of treasury
	uint256 internal constant TOKEN = 0;

	mapping(bytes32 => mapping(uint256 => uint256)) public balanceOf;

	mapping(uint256 => uint256) public totalSupply;

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 LOGIC
	/// ----------------------------------------------------------------------------------------

	function balanceOfBatch(
		bytes32[] memory owners,
		uint256[] memory ids
	) public view virtual returns (uint256[] memory balances) {
		uint256 ownersLength = owners.length; // Saves MLOADs.

		require(ownersLength == ids.length, 'LENGTH_MISMATCH');

		balances = new uint256[](owners.length);

		// Unchecked because the only math done is incrementing
		// the array index counter which cannot possibly overflow.
		unchecked {
			for (uint256 i = 0; i < ownersLength; i++) {
				balances[i] = balanceOf[owners[i]][ids[i]];
			}
		}
	}

	/// ----------------------------------------------------------------------------------------
	///						INTERNAL MINT/BURN  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _mint(bytes32 to, uint256 id, uint256 amount, bytes memory data) internal {
		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value
		unchecked {
			balanceOf[to][id] += amount;
			totalSupply[id] += amount;
		}

		// emit TransferSingle(msg.sender, address(0), to, id, amount);
	}

	function _batchMint(
		bytes32 to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			// An array can't have a total length
			// larger than / the sum of balances can't
			// exceed the max uint256 value
			unchecked {
				balanceOf[to][ids[i]] += amounts[i];
				totalSupply[ids[i]] += amounts[i];
				++i;
			}
		}

		//emit TransferBatch(msg.sender, address(0), to, ids, amounts);
	}

	function _batchBurn(bytes32 from, uint256[] memory ids, uint256[] memory amounts) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[from][ids[i]] -= amounts[i];

			totalSupply[ids[i]] -= amounts[i];

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				++i;
			}
		}

		//emit TransferBatch(msg.sender, from, address(0), ids, amounts);
	}

	function _burn(bytes32 from, uint256 id, uint256 amount) internal {
		balanceOf[from][id] -= amount;

		totalSupply[id] -= amount;

		//emit TransferSingle(msg.sender, from, address(0), id, amount);
	}
}
