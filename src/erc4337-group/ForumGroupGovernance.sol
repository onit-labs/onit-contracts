// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// @notice Minimalist and gas efficient ERC1155 based DAO implementation with governance.
/// @author Modified from Solbase ERC1155.sol

// TODO
// - Add uri to get image for nfts
// - Consider adding token delegation
// - Add erc1155 handling to individual accounts
// - Add erc2612  style domain separator
// - Set name & symbol

abstract contract ForumGroupGovernance {
	/// ----------------------------------------------------------------------------------------
	///							EVENTS
	/// ----------------------------------------------------------------------------------------

	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 amount
	);

	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] amounts
	);

	event ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved);

	event PauseFlipped(bool indexed paused);

	/// ----------------------------------------------------------------------------------------
	///							ERRORS
	/// ----------------------------------------------------------------------------------------

	error Paused();

	error InvalidNonce();

	/// ----------------------------------------------------------------------------------------
	///							METADATA STORAGE
	/// ----------------------------------------------------------------------------------------

	string public name;

	string public symbol;

	uint8 public constant DECIMALS = 18;

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 STORAGE
	/// ----------------------------------------------------------------------------------------

	mapping(address => mapping(uint256 => uint256)) public balanceOf;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/// ----------------------------------------------------------------------------------------
	///							GROUP STORAGE
	/// ----------------------------------------------------------------------------------------

	bool public paused;

	// DAO token representing voting share of treasury
	uint256 internal constant TOKEN = 0;

	mapping(uint256 => uint256) public totalSupply;

	/// ----------------------------------------------------------------------------------------
	///							CONSTRUCTOR
	/// ----------------------------------------------------------------------------------------

	function _init(string memory name_, string memory symbol_) internal virtual {
		name = name_;

		symbol = symbol_;

		paused = true;
	}

	/// ----------------------------------------------------------------------------------------
	///							ERC1155 LOGIC
	/// ----------------------------------------------------------------------------------------

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual notPaused {
		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		balanceOf[from][id] -= amount;
		balanceOf[to][id] += amount;

		emit TransferSingle(msg.sender, from, to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual notPaused {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		for (uint256 i = 0; i < idsLength; ) {
			uint256 id = ids[i];
			uint256 amount = amounts[i];

			balanceOf[from][id] -= amount;
			balanceOf[to][id] += amount;

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				++i;
			}
		}

		emit TransferBatch(msg.sender, from, to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
					msg.sender,
					from,
					ids,
					amounts,
					data
				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function balanceOfBatch(
		address[] memory owners,
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
	///							GROUP LOGIC
	/// ----------------------------------------------------------------------------------------

	modifier notPaused() {
		if (paused) revert Paused();
		_;
	}

	/// ----------------------------------------------------------------------------------------
	///							ERC-165 LOGIC
	/// ----------------------------------------------------------------------------------------

	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0xd9b67a26; // ERC165 Interface ID for ERC1155
	}

	/// ----------------------------------------------------------------------------------------
	///						INTERNAL MINT/BURN  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
		// Cannot overflow because the sum of all user
		// balances can't exceed the max uint256 value
		unchecked {
			balanceOf[to][id] += amount;
			totalSupply[id] += amount;
		}

		emit TransferSingle(msg.sender, address(0), to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(
					msg.sender,
					address(0),
					id,
					amount,
					data
				) == ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchMint(
		address to,
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

		emit TransferBatch(msg.sender, address(0), to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
					msg.sender,
					address(0),
					ids,
					amounts,
					data
				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal {
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

		emit TransferBatch(msg.sender, from, address(0), ids, amounts);
	}

	function _burn(address from, uint256 id, uint256 amount) internal {
		balanceOf[from][id] -= amount;

		totalSupply[id] -= amount;

		emit TransferSingle(msg.sender, from, address(0), id, amount);
	}

	/// ----------------------------------------------------------------------------------------
	///						PAUSE  LOGIC
	/// ----------------------------------------------------------------------------------------

	function _flipPause() internal virtual {
		paused = !paused;

		emit PauseFlipped(paused);
	}
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external returns (bytes4);

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external returns (bytes4);
}
