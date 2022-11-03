// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../interfaces/IAccessManager.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IERC2981.sol';
import '../utils/tokens/erc1155/ERC1155.sol';

import '../utils/Owned.sol';

contract AccessManager is ERC1155, IERC2981, IAccessManager, Owned {
	/*///////////////////////////////////////////////////////////////
													EVENTS
	//////////////////////////////////////////////////////////////*/

	event ItemMinted(address indexed account, uint256 indexed tokenId, uint256 indexed level);

	event ItemAdded(uint256 indexed tokenId, uint256 indexed level);

	event ItemMintLive(uint256 tokenId, bool setting);

	/*///////////////////////////////////////////////////////////////
													ERRORS
	//////////////////////////////////////////////////////////////*/

	error Unauthorised();

	error MintingClosed();

	error InvalidItem();

	error ItemUnavailable();

	error AlreadyOwner();

	error InsufficientLevel();

	error IncorrectValue();

	/*///////////////////////////////////////////////////////////////
													ACCESS STORAGE
	//////////////////////////////////////////////////////////////*/

	address public forumRelay;

	string public name;
	string public symbol;
	string public baseURI;

	uint256 internal itemCount;

	// Access Levels
	uint256 constant NONE = uint256(AccessLevels.NONE);
	uint256 constant BASIC = uint256(AccessLevels.BASIC);
	uint256 constant BRONZE = uint256(AccessLevels.BRONZE);
	uint256 constant SILVER = uint256(AccessLevels.SILVER);
	uint256 constant GOLD = uint256(AccessLevels.GOLD);

	// Discounts on items (based of 10000 = 100%)
	uint256 internal goldLevelDiscount = 10000;
	uint256 internal silverLevelDiscount = 5000;
	uint256 internal bronzeLevelDiscount = 1000;

	mapping(uint256 => Item) private itemList;
	mapping(address => uint256) public memberLevel;
	mapping(address => mapping(uint256 => bool)) public forumWhitelist;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

	constructor(
		address deployer,
		string memory name_,
		string memory symbol_,
		string memory baseURI_
	) Owned(deployer) {
		name = name_;

		symbol = symbol_;

		baseURI = baseURI_;

		emit URI(baseURI, 0);

		// Add placeholder items for NONE level item
		itemList[itemCount] = Item({
			live: true,
			price: 0,
			maxSupply: 0,
			currentSupply: 0,
			accessLevel: 0,
			resaleRoyalty: 0
		});

		emit ItemAdded(itemCount, itemList[itemCount].accessLevel);
		++itemCount;
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	// Sets the relay and assignes GOLD access (this allows free minting, without adding any logic)
	function setForumRelay(address relay) external onlyOwner {
		forumRelay = relay;
		memberLevel[relay] = GOLD;
	}

	function collectFees() external onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}(new bytes(0));
		require(success, 'AccessManager: Transfer failed');
	}

	function collectERC20(IERC20 erc20) external onlyOwner {
		IERC20(erc20).transfer(owner, erc20.balanceOf(address(this)));
	}

	function setURI(string memory baseURI_) external onlyOwner {
		baseURI = baseURI_;

		emit URI(baseURI, 0);
	}

	function addItem(
		uint256 price,
		uint256 itemSupply,
		uint256 accessLevel,
		uint256 resaleRoyalty
	) external onlyOwner {
		itemList[itemCount] = Item({
			live: false,
			price: price,
			maxSupply: itemSupply,
			currentSupply: 0,
			accessLevel: accessLevel,
			resaleRoyalty: resaleRoyalty
		});

		emit ItemAdded(itemCount, accessLevel);

		++itemCount;
	}

	function setItemMintLive(uint256 itemId, bool setting) external onlyOwner {
		itemList[itemId].live = setting;

		emit ItemMintLive(itemCount, setting);
	}

	function mintAndDrop(
		uint256[] calldata tokenId,
		uint256[] calldata amount,
		address[] calldata receivers
	) external {
		if (!(msg.sender == owner || msg.sender == forumRelay)) revert Unauthorised();

		if (tokenId[0] > itemCount) revert InvalidItem();

		if (itemList[tokenId[0]].currentSupply + amount[0] > itemList[tokenId[0]].maxSupply)
			revert ItemUnavailable();

		_batchMint(msg.sender, tokenId, amount, '');

		for (uint256 i = 0; i < receivers.length; ) {
			if (balanceOf[receivers[i]][tokenId[0]] == 0) {
				safeTransferFrom(msg.sender, receivers[i], tokenId[0], 1, '');
			}

			// Receives will never be a large number
			unchecked {
				++i;
			}
		}
	}

	// Owner or relay can set whitelist
	function toggleItemWhitelist(address user, uint256 itemId) external {
		if (!(msg.sender == owner || msg.sender == forumRelay)) revert Unauthorised();

		forumWhitelist[user][itemId] = !forumWhitelist[user][itemId];
	}

	/// ----------------------------------------------------------------------------------------
	/// Public Interface
	/// ----------------------------------------------------------------------------------------

	function mintItem(uint256 itemId, address member) external payable {
		// If minting not live only a whitelisted member or the relay can mint
		if (!itemList[itemId].live && !(forumWhitelist[member][itemId] || msg.sender == forumRelay))
			revert MintingClosed();

		if (itemList[itemId].currentSupply == itemList[itemId].maxSupply) revert ItemUnavailable();

		// These are acces passes and members can only have 1 of each
		if (balanceOf[member][itemId] > 0) revert AlreadyOwner();

		if (msg.value != discountedPrice(itemId, member)) revert IncorrectValue();

		// If item is a level pass
		if (itemId <= GOLD) {
			// If user does not already have a higher level pass, update their global level
			// If user already has a level pass, revert since the upgradeLevel function should be called
			if (memberLevel[member] < BRONZE) memberLevel[member] = itemId;
			else revert InvalidItem();
		}

		_mint(member, itemId, 1, '');
		++itemList[itemId].currentSupply;

		emit ItemMinted(member, itemId, itemList[itemId].accessLevel);
	}

	function upgradeLevel(uint256 itemId, address member) external payable {
		if (memberLevel[member] == NONE) revert Unauthorised();

		if (itemId > GOLD) revert InvalidItem();

		if (itemId <= memberLevel[member]) revert InvalidItem();

		if (itemList[itemId].currentSupply >= itemList[itemId].maxSupply) revert ItemUnavailable();

		if (msg.value != itemList[itemId].price - itemList[memberLevel[member]].price)
			revert IncorrectValue();

		// Burn current level item, then mint new level and adjust supply
		_burn(member, memberLevel[member], 1);
		--itemList[memberLevel[member]].currentSupply;

		_mint(member, itemId, 1, '');
		++itemList[itemId].currentSupply;

		memberLevel[member] = itemId;

		emit ItemMinted(member, itemId, itemList[itemId].accessLevel);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		// If item is a membership level
		if (id <= GOLD)
			if (
				// New level must be higher than old to prevent forced transfer to lower level.
				memberLevel[to] < id
			) {
				// Update receivers level
				memberLevel[to] = id;
				// Set the transferrer back to basic level -> NONE
				memberLevel[from] = NONE;
			} else {
				revert InvalidItem();
			}

		super.safeTransferFrom(from, to, id, amount, data);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		uint256 idsLength = ids.length; // Saves MLOADs.

		if (idsLength != amounts.length) revert InvalidItem();

		if (!(msg.sender == from || isApprovedForAll[from][msg.sender])) revert Unauthorised();

		// Storing these outside the loop saves ~15 gas per iteration.
		uint256 id;
		uint256 amount;

		for (uint256 i = 0; i < idsLength; ) {
			id = ids[i];
			amount = amounts[i];

			// If item is a membership level
			if (id <= GOLD)
				if (
					// New level must be higher than old to prevent forced transfer to lower level.
					memberLevel[to] < id
				) {
					// Update receivers level
					memberLevel[to] = id;
					// Set the transferrer back to basic level -> NONE
					memberLevel[from] = NONE;
				} else {
					revert InvalidItem();
				}

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
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
					ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	/// ----------------------------------------------------------------------------------------
	/// Public View Functions
	/// ----------------------------------------------------------------------------------------

	function uri(uint256 id) public view override returns (string memory) {
		return string(abi.encodePacked(baseURI, uint2str(id), '.json'));
	}

	function getItemCount() public view returns (uint256) {
		return itemCount;
	}

	function itemDetails(uint256 item) public view returns (Item memory) {
		return itemList[item];
	}

	function discountedPrice(uint256 itemId, address member) public returns (uint256 price) {
		// If memberLevel >= level for this item, member doesnt pay -> this covers gold level
		if (memberLevel[member] >= itemList[itemId].accessLevel) {
			return 0;
		}

		// If Whitelist
		if (forumWhitelist[member][itemId]) {
			forumWhitelist[member][itemId] = false;
			return 0;
		}

		// Non-member pays full price
		if (memberLevel[member] == NONE || memberLevel[member] == BASIC) {
			return itemList[itemId].price;
		}

		if (memberLevel[member] == BRONZE) {
			return itemList[itemId].price - (itemList[itemId].price * bronzeLevelDiscount) / 10000;
		}

		if (memberLevel[member] == SILVER) {
			return itemList[itemId].price - (itemList[itemId].price * silverLevelDiscount) / 10000;
		}
	}

	function royaltyInfo(uint256 tokenId, uint256 salePrice)
		public
		view
		returns (address receiver, uint256 royaltyAmount)
	{
		receiver = address(this);

		royaltyAmount = (salePrice * itemList[tokenId].resaleRoyalty) / 10000;

		return (receiver, royaltyAmount);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC1155, IERC165)
		returns (bool)
	{
		return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
	}

	/// ----------------------------------------------------------------------------------------
	/// Internal Interface
	/// ----------------------------------------------------------------------------------------

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return '0';
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}
}
