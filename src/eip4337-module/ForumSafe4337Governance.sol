// // SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity ^0.8.15;

// import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

// import {SafeHelper, Enum} from '@utils/SafeHelper.sol';

// /// @notice Minimalist and gas efficient ERC1155 based DAO implementation with governance.
// /// @author Modified from KaliDAO (https://github.com/kalidao/kali-contracts/blob/main/contracts/KaliDAOtoken.sol)

// ! THIS WILL BE UPDATED WHEN NEW INDIVIDUAL ACCOUNT IS COMPLETE

// abstract contract ForumGovernance is SafeHelper {
// 	using EnumerableSet for EnumerableSet.AddressSet;

// 	/// ----------------------------------------------------------------------------------------
// 	///							EVENTS
// 	/// ----------------------------------------------------------------------------------------

// 	event TransferSingle(
// 		address indexed operator,
// 		address indexed from,
// 		address indexed to,
// 		uint256 id,
// 		uint256 amount
// 	);

// 	event TransferBatch(
// 		address indexed operator,
// 		address indexed from,
// 		address indexed to,
// 		uint256[] ids,
// 		uint256[] amounts
// 	);

// 	event ApprovalForAll(address indexed owner, address indexed operator, bool indexed approved);

// 	event URI(string value, uint256 indexed id);

// 	event PauseFlipped(bool indexed paused);

// 	event Delegation(
// 		address indexed delegator,
// 		address indexed currentDelegatee,
// 		address indexed delegatee
// 	);

// 	/// ----------------------------------------------------------------------------------------
// 	///							ERRORS
// 	/// ----------------------------------------------------------------------------------------

// 	error Paused();

// 	error SignatureExpired();

// 	error InvalidDelegate();

// 	error Uint32max();

// 	error Uint96max();

// 	error InvalidNonce();

// 	/// ----------------------------------------------------------------------------------------
// 	///							METADATA STORAGE
// 	/// ----------------------------------------------------------------------------------------

// 	string public name;

// 	string public symbol;

// 	uint8 public constant DECIMALS = 18;

// 	/// ----------------------------------------------------------------------------------------
// 	///							ERC1155 STORAGE
// 	/// ----------------------------------------------------------------------------------------

// 	uint256 public totalSupply;

// 	mapping(address => mapping(uint256 => uint256)) public balanceOf;

// 	mapping(address => mapping(address => bool)) public isApprovedForAll;

// 	/// ----------------------------------------------------------------------------------------
// 	///							EIP-712 STORAGE
// 	/// ----------------------------------------------------------------------------------------

// 	bytes32 internal INITIAL_DOMAIN_SEPARATOR;

// 	uint256 internal INITIAL_CHAIN_ID;

// 	mapping(address => uint256) public nonces;

// 	/// ----------------------------------------------------------------------------------------
// 	///							GROUP STORAGE
// 	/// ----------------------------------------------------------------------------------------

// 	bool public paused;

// 	bytes32 public constant DELEGATION_TYPEHASH =
// 		keccak256('Delegation(address delegatee,uint256 nonce,uint256 deadline)');

// 	// DAO token representing voting share of treasury
// 	uint256 internal constant TOKEN = 0;

// 	// All delegators for a member -> default case is an empty array
// 	mapping(address => EnumerableSet.AddressSet) internal memberDelegators;
// 	// The current delegate of a member -> default is no delegation, ie address(0)
// 	mapping(address => address) public memberDelegatee;

// 	/// ----------------------------------------------------------------------------------------
// 	///							CONSTRUCTOR
// 	/// ----------------------------------------------------------------------------------------

// 	function _init(string memory name_, string memory symbol_) internal virtual {
// 		name = name_;

// 		symbol = symbol_;

// 		paused = true;

// 		INITIAL_CHAIN_ID = block.chainid;

// 		INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
// 	}

// 	/// ----------------------------------------------------------------------------------------
// 	///							METADATA LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	function uri(uint256 id) public view virtual returns (string memory);

// 	/// ----------------------------------------------------------------------------------------
// 	///							ERC1155 LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	function setApprovalForAll(address operator, bool approved) public virtual {
// 		isApprovedForAll[msg.sender][operator] = approved;

// 		emit ApprovalForAll(msg.sender, operator, approved);
// 	}

// 	function safeTransferFrom(
// 		address from,
// 		address to,
// 		uint256 id,
// 		uint256 amount,
// 		bytes memory data
// 	) public virtual notPaused {
// 		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

// 		balanceOf[from][id] -= amount;
// 		balanceOf[to][id] += amount;

// 		// Cannot transfer membership while delegating / being delegated to
// 		if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
// 			revert InvalidDelegate();

// 		emit TransferSingle(msg.sender, from, to, id, amount);

// 		require(
// 			to.code.length == 0
// 				? to != address(0)
// 				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
// 					ERC1155TokenReceiver.onERC1155Received.selector,
// 			'UNSAFE_RECIPIENT'
// 		);
// 	}

// 	function safeBatchTransferFrom(
// 		address from,
// 		address to,
// 		uint256[] memory ids,
// 		uint256[] memory amounts,
// 		bytes memory data
// 	) public virtual notPaused {
// 		uint256 idsLength = ids.length; // Saves MLOADs.

// 		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

// 		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

// 		for (uint256 i = 0; i < idsLength; ) {
// 			uint256 id = ids[i];
// 			uint256 amount = amounts[i];

// 			balanceOf[from][id] -= amount;
// 			balanceOf[to][id] += amount;

// 			// Cannot transfer membership while delegating / being delegated to
// 			if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
// 				revert InvalidDelegate();

// 			// An array can't have a total length
// 			// larger than the max uint256 value.
// 			unchecked {
// 				i++;
// 			}
// 		}

// 		emit TransferBatch(msg.sender, from, to, ids, amounts);

// 		require(
// 			to.code.length == 0
// 				? to != address(0)
// 				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
// 					msg.sender,
// 					from,
// 					ids,
// 					amounts,
// 					data
// 				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
// 			'UNSAFE_RECIPIENT'
// 		);
// 	}

// 	function balanceOfBatch(
// 		address[] memory owners,
// 		uint256[] memory ids
// 	) public view virtual returns (uint256[] memory balances) {
// 		uint256 ownersLength = owners.length; // Saves MLOADs.

// 		require(ownersLength == ids.length, 'LENGTH_MISMATCH');

// 		balances = new uint256[](owners.length);

// 		// Unchecked because the only math done is incrementing
// 		// the array index counter which cannot possibly overflow.
// 		unchecked {
// 			for (uint256 i = 0; i < ownersLength; i++) {
// 				balances[i] = balanceOf[owners[i]][ids[i]];
// 			}
// 		}
// 	}

// 	/// ----------------------------------------------------------------------------------------
// 	///							EIP-2612 LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
// 		return
// 			block.chainid == INITIAL_CHAIN_ID
// 				? INITIAL_DOMAIN_SEPARATOR
// 				: _computeDomainSeparator();
// 	}

// 	function _computeDomainSeparator() internal view virtual returns (bytes32) {
// 		return
// 			keccak256(
// 				abi.encode(
// 					keccak256(
// 						'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
// 					),
// 					keccak256(bytes(name)),
// 					keccak256('1.1.0'),
// 					block.chainid,
// 					address(this)
// 				)
// 			);
// 	}

// 	/// ----------------------------------------------------------------------------------------
// 	///							GROUP LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	modifier notPaused() {
// 		if (paused) revert Paused();
// 		_;
// 	}

// 	function delegators(address delegatee) public view virtual returns (address[] memory) {
// 		return EnumerableSet.values(memberDelegators[delegatee]);
// 	}

// 	function delegate(address delegatee) public payable virtual {
// 		_delegate(msg.sender, delegatee);
// 	}

// 	function delegateBySig(
// 		address delegatee,
// 		uint256 nonce,
// 		uint256 deadline,
// 		uint8 v,
// 		bytes32 r,
// 		bytes32 s
// 	) public payable virtual {
// 		if (block.timestamp > deadline) revert SignatureExpired();

// 		bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, deadline));

// 		bytes32 digest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR(), structHash));

// 		address signatory = ecrecover(digest, v, r, s);

// 		if (!isOwner(signatory)) revert InvalidDelegate();

// 		// cannot realistically overflow on human timescales
// 		unchecked {
// 			if (nonce != nonces[signatory]++) revert InvalidNonce();
// 		}

// 		_delegate(signatory, delegatee);
// 	}

// 	function removeDelegator(address delegator) public virtual {
// 		// Verify msg.sender is being delegated to by the delegator
// 		if (memberDelegatee[delegator] != msg.sender) revert InvalidDelegate();
// 		_delegate(delegator, msg.sender);
// 	}

// 	function _delegate(address delegator, address delegatee) internal {
// 		// Can only delegate from/to existing members
// 		if (!(isOwner(msg.sender) && isOwner(delegatee))) revert InvalidDelegate();

// 		address currentDelegatee = memberDelegatee[delegator];

// 		// Can not delegate to others if delegated to
// 		if (memberDelegators[delegator].length() > 0) revert InvalidDelegate();

// 		// If delegator is currently delegating
// 		if (currentDelegatee != address(0)) {
// 			// 1) remove delegator from the memberDelegators list of their delegatee
// 			memberDelegators[currentDelegatee].remove(delegator);

// 			// 2) reset delegator memberDelegatee to address(0)
// 			memberDelegatee[delegator] = address(0);

// 			emit Delegation(delegator, currentDelegatee, address(0));

// 			// If delegator is not currently delegating
// 		} else {
// 			// 1) add the delegator to the memberDelegators list of their new delegatee
// 			memberDelegators[delegatee].add(delegator);

// 			// 2) set the memberDelegatee of the delegator to the new delegatee
// 			memberDelegatee[delegator] = delegatee;

// 			emit Delegation(delegator, currentDelegatee, delegatee);
// 		}
// 	}

// 	/// ----------------------------------------------------------------------------------------
// 	///							ERC-165 LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
// 		return
// 			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
// 			interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
// 			interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
// 	}

// 	/// ----------------------------------------------------------------------------------------
// 	///						INTERNAL MINT/BURN  LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal {
// 		// Cannot overflow because the sum of all user
// 		// balances can't exceed the max uint256 value
// 		unchecked {
// 			balanceOf[to][id] += amount;
// 		}

// 		// If token is being updated, update total supply
// 		if (id == TOKEN) {
// 			totalSupply += amount;
// 		}

// 		emit TransferSingle(msg.sender, address(0), to, id, amount);

// 		require(
// 			to.code.length == 0
// 				? to != address(0)
// 				: ERC1155TokenReceiver(to).onERC1155Received(
// 					msg.sender,
// 					address(0),
// 					id,
// 					amount,
// 					data
// 				) == ERC1155TokenReceiver.onERC1155Received.selector,
// 			'UNSAFE_RECIPIENT'
// 		);
// 	}

// 	function _batchMint(
// 		address to,
// 		uint256[] memory ids,
// 		uint256[] memory amounts,
// 		bytes memory data
// 	) internal {
// 		uint256 idsLength = ids.length; // Saves MLOADs.

// 		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

// 		for (uint256 i = 0; i < idsLength; ) {
// 			balanceOf[to][ids[i]] += amounts[i];

// 			// If token is being updated, update total supply
// 			if (ids[i] == TOKEN) {
// 				totalSupply += amounts[i];
// 			}

// 			// An array can't have a total length
// 			// larger than the max uint256 value.
// 			unchecked {
// 				i++;
// 			}
// 		}

// 		emit TransferBatch(msg.sender, address(0), to, ids, amounts);

// 		require(
// 			to.code.length == 0
// 				? to != address(0)
// 				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
// 					msg.sender,
// 					address(0),
// 					ids,
// 					amounts,
// 					data
// 				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
// 			'UNSAFE_RECIPIENT'
// 		);
// 	}

// 	function _batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) internal {
// 		uint256 idsLength = ids.length; // Saves MLOADs.

// 		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

// 		for (uint256 i = 0; i < idsLength; ) {
// 			balanceOf[from][ids[i]] -= amounts[i];

// 			// Member can not leave while delegating / being delegated to
// 			if (memberDelegatee[from] != address(0) || memberDelegators[from].length() > 0)
// 				revert InvalidDelegate();

// 			// If token is being updated, update total supply
// 			if (ids[i] == TOKEN) {
// 				totalSupply -= amounts[i];
// 			}

// 			// An array can't have a total length
// 			// larger than the max uint256 value.
// 			unchecked {
// 				i++;
// 			}
// 		}

// 		emit TransferBatch(msg.sender, from, address(0), ids, amounts);
// 	}

// 	function _burn(address from, uint256 id, uint256 amount) internal {
// 		balanceOf[from][id] -= amount;

// 		// Member can not leave while delegating / being delegated to
// 		if (memberDelegatee[from] != address(0) || EnumerableSet.length(memberDelegators[from]) > 0)
// 			revert InvalidDelegate();

// 		// If token is being updated, update total supply
// 		if (id == TOKEN) {
// 			totalSupply -= amount;
// 		}

// 		emit TransferSingle(msg.sender, from, address(0), id, amount);
// 	}

// 	/// ----------------------------------------------------------------------------------------
// 	///						PAUSE  LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	function _flipPause() internal virtual {
// 		paused = !paused;

// 		emit PauseFlipped(paused);
// 	}

// 	/// ----------------------------------------------------------------------------------------
// 	///						SAFECAST  LOGIC
// 	/// ----------------------------------------------------------------------------------------

// 	function _safeCastTo32(uint256 x) internal pure virtual returns (uint32) {
// 		if (x > type(uint32).max) revert Uint32max();

// 		return uint32(x);
// 	}

// 	function _safeCastTo96(uint256 x) internal pure virtual returns (uint96) {
// 		if (x > type(uint96).max) revert Uint96max();

// 		return uint96(x);
// 	}
// }

// /// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
// /// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
// interface ERC1155TokenReceiver {
// 	function onERC1155Received(
// 		address operator,
// 		address from,
// 		uint256 id,
// 		uint256 amount,
// 		bytes calldata data
// 	) external returns (bytes4);

// 	function onERC1155BatchReceived(
// 		address operator,
// 		address from,
// 		uint256[] calldata ids,
// 		uint256[] calldata amounts,
// 		bytes calldata data
// 	) external returns (bytes4);
// }
