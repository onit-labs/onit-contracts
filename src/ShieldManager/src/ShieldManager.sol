// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import '../../interfaces/IERC20.sol';
import '../../interfaces/ICategories.sol';
import '../../interfaces/IEmblemWeaver.sol';
import '../../interfaces/IShieldManager.sol';
import '../../interfaces/IPfpStaker.sol';

import '../../utils/tokens/erc721/ERC721.sol';
import '../../utils/Owned.sol';

import '../../libraries/HexStrings.sol';

contract ShieldManager is Owned, ERC721, IShieldManager {
	using HexStrings for uint16;

	/*///////////////////////////////////////////////////////////////
													EVENTS
	//////////////////////////////////////////////////////////////*/

	event ShieldBuilt(
		address indexed builder,
		uint256 indexed tokenId,
		bytes32 oldShieldHash,
		bytes32 newShieldHash,
		uint16 field,
		uint16[9] hardware,
		uint16 frame,
		uint24[4] colors
	);

	event MintingStatus(bool live);

	/*///////////////////////////////////////////////////////////////
													ERRORS
	//////////////////////////////////////////////////////////////*/

	error MintingClosed();

	error DuplicateShield();

	error InvalidShield();

	error ColorError();

	error IncorrectValue();

	error Unauthorised();

	/*///////////////////////////////////////////////////////////////
												SHIELD	STORAGE
	//////////////////////////////////////////////////////////////*/

	// Contracts
	IEmblemWeaver public emblemWeaver;
	IPfpStaker public pfpStaker;

	// Roundtable Contract Addresses
	address payable public roundtableFactory;
	address payable public roundtableRelay;

	// Fees
	uint256 epicFieldFee = 0.1 ether;
	uint256 heroicFieldFee = 0.25 ether;
	uint256 olympicFieldFee = 0.5 ether;
	uint256 legendaryFieldFee = 1 ether;

	uint256 epicHardwareFee = 0.1 ether;
	uint256 doubleHardwareFee = 0.2 ether;
	uint256 multiHardwareFee = 0.3 ether;

	uint256 adornedFrameFee = 0.1 ether;
	uint256 menacingFrameFee = 0.25 ether;
	uint256 securedFrameFee = 0.5 ether;
	uint256 floriatedFrameFee = 1 ether;
	uint256 everlastingFrameFee = 2 ether;

	uint256 shieldPassPrice = 0.5 ether;

	uint256 private _currentId = 1;
	uint256 public preLaunchSupply = 120;

	bool public publicMintActive = false;

	// Transient variable that's immediately cleared after checking for duplicate colors
	mapping(uint24 => bool) private _checkDuplicateColors;
	// Store of all shields
	mapping(uint256 => Shield) private _shields;
	// Hashes that let us check for duplicates
	mapping(bytes32 => bool) public shieldHashes;
	// Whitelist for each type of reward
	mapping(address => mapping(WhitelistItems => bool)) public whitelist;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/
	constructor(
		address deployer,
		string memory name_,
		string memory symbol_,
		IEmblemWeaver _emblemWeaver
	) ERC721(name_, symbol_) Owned(deployer) {
		emblemWeaver = _emblemWeaver;
	}

	// ============ OWNER INTERFACE ============

	function collectFees() external onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}(new bytes(0));
		require(success, 'ShieldManager: Transfer failed');
	}

	function collectERC20(IERC20 erc20) external onlyOwner {
		IERC20(erc20).transfer(owner, erc20.balanceOf(address(this)));
	}

	function setPublicMintActive(bool setting) external onlyOwner {
		publicMintActive = setting;

		emit MintingStatus(setting);
	}

	// Owner or relay can set whitelist
	function toggleItemWhitelist(address user, WhitelistItems itemId) external {
		if (!(msg.sender == owner || msg.sender == roundtableRelay)) revert Unauthorised();

		whitelist[user][itemId] = !whitelist[user][itemId];
	}

	function setPreLaunchSupply(uint256 supply) external onlyOwner {
		preLaunchSupply = supply;
	}

	function setShieldPassPrice(uint256 _shieldPassPrice) external onlyOwner {
		shieldPassPrice = _shieldPassPrice;
	}

	// Allows for price adjustments
	function setShieldItemPrices(
		uint256[] calldata fieldPrices,
		uint256[] calldata hardwarePrices,
		uint256[] calldata framePrices
	) external onlyOwner {
		if (fieldPrices.length != 0) {
			epicFieldFee = fieldPrices[0];
			heroicFieldFee = fieldPrices[1];
			olympicFieldFee = fieldPrices[2];
			legendaryFieldFee = fieldPrices[3];
		}

		if (hardwarePrices.length != 0) {
			epicHardwareFee = hardwarePrices[0];
			doubleHardwareFee = hardwarePrices[1];
			multiHardwareFee = hardwarePrices[2];
		}

		if (framePrices.length != 0) {
			adornedFrameFee = framePrices[0];
			menacingFrameFee = framePrices[1];
			securedFrameFee = framePrices[2];
			floriatedFrameFee = framePrices[3];
			everlastingFrameFee = framePrices[4];
		}
	}

	function setRoundtableRelay(address payable relay) external onlyOwner {
		roundtableRelay = relay;
	}

	function setRoundtableFactory(address payable factory) external onlyOwner {
		roundtableFactory = factory;
	}

	function setEmblemWeaver(address payable emblemWeaver_) external onlyOwner {
		emblemWeaver = IEmblemWeaver(emblemWeaver_);
	}

	function setPfpStaker(address payable pfpStaker_) external onlyOwner {
		pfpStaker = IPfpStaker(pfpStaker_);
	}

	function buildAndDropShields(address[] calldata receivers, Shield[] calldata shieldBatch)
		external
	{
		if (msg.sender != roundtableRelay) revert Unauthorised();

		uint256 len = receivers.length;
		uint256 id = _currentId;

		for (uint256 i = 0; i < len; ) {
			buildShield(
				shieldBatch[i].field,
				shieldBatch[i].hardware,
				shieldBatch[i].frame,
				shieldBatch[i].colors,
				id + i
			);

			ownerOf[id + i] = receivers[i];
			emit Transfer(msg.sender, receivers[i], id + i);

			// Receives will never be a large number
			unchecked {
				++i;
			}
		}
		// Receives will never be a large number
		// Updated apart from the above code to save writes to storage
		unchecked {
			_currentId += len;
		}
	}

	// ============ PUBLIC INTERFACE ============

	function mintShieldPass(address to) public payable returns (uint256) {
		// If not minted by factory or relay
		if (!(msg.sender == roundtableFactory || msg.sender == roundtableRelay)) {
			// Check correct price was paid
			if (msg.value != shieldPassPrice) revert IncorrectValue();
			// If pre-launch, ensure currentId is less than preLaunchSupply
			if (!publicMintActive)
				if (!whitelist[to][WhitelistItems.MINT_SHIELD_PASS] && _currentId > preLaunchSupply)
					revert MintingClosed();
		}

		_mint(to, _currentId);

		// Return the id of the token minted, then increment currentId
		unchecked {
			return _currentId++;
		}
	}

	function buildShield(
		uint16 field,
		uint16[9] calldata hardware,
		uint16 frame,
		uint24[4] memory colors,
		uint256 tokenId
	) public payable {
		// Can only be built by owner of tokenId or relay. If staked in pfpStaker, if can be built by the staker.
		if (!(msg.sender == ownerOf[tokenId] || msg.sender == roundtableRelay)) {
			(address NFTContract, uint256 stakedToken) = pfpStaker.getStakedNFT();

			if (!(NFTContract == address(this) && stakedToken == tokenId)) revert Unauthorised();
		}

		validateColors(colors, field);

		// Here we combine the hardware items into a single string
		bytes32 fullHardware;
		{
			string memory combinedHardware;
			string memory currentHardwareItem;

			// Will not over or underflow due to i > 0 check and array length = 9
			unchecked {
				for (uint16 i; i < 9; ) {
					if (i > 0) {
						// If new hardware item differs to previous, generate the padded string
						if (hardware[i] != hardware[i - 1])
							currentHardwareItem = hardware[i].toHexStringNoPrefix(2);
						// Else reuse currentHardwareItem
						combinedHardware = string(abi.encodePacked(combinedHardware, currentHardwareItem));
						// When i=0 set currentHardwareItem to first item
					} else {
						currentHardwareItem = hardware[i].toHexStringNoPrefix(2);
						combinedHardware = currentHardwareItem;
					}
					++i;
				}
			}
			fullHardware = keccak256(bytes(combinedHardware));
		}

		// We then hash the field, hardware and frame to give a unique shield hash
		bytes32 newShieldHash = keccak256(
			abi.encodePacked(field.toHexStringNoPrefix(2), fullHardware, frame.toHexStringNoPrefix(2))
		);

		if (shieldHashes[newShieldHash]) revert DuplicateShield();

		Shield memory oldShield = _shields[tokenId];

		// Set new shield hash to prevent duplicates, and remove old shield to free design
		shieldHashes[oldShield.shieldHash] = false;
		shieldHashes[newShieldHash] = true;

		uint256 fee;
		uint256 tmpOldPrice;
		uint256 tmpNewPrice;

		if (_shields[tokenId].colors[0] == 0) {
			fee += calculateFieldFee(field, colors);
			fee += calculateHardwareFee(hardware);
			fee += calculateFrameFee(frame);
		} else {
			// This prevents Roundtable from editing a shield after it is created
			if (msg.sender == roundtableRelay) revert Unauthorised();

			if (field != oldShield.field) {
				tmpOldPrice = calculateFieldFee(oldShield.field, oldShield.colors);
				tmpNewPrice = calculateFieldFee(field, colors);

				fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
			}

			if (fullHardware != oldShield.hardwareConfiguration) {
				tmpOldPrice = calculateHardwareFee(oldShield.hardware);
				tmpNewPrice = calculateHardwareFee(hardware);

				fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
			}

			if (frame != oldShield.frame) {
				tmpOldPrice = calculateFrameFee(oldShield.frame);
				tmpNewPrice = calculateFrameFee(frame);

				fee += tmpNewPrice < tmpOldPrice ? 0 : tmpNewPrice - tmpOldPrice;
			}
		}

		if (msg.value != fee && msg.sender != roundtableRelay) {
			if (whitelist[msg.sender][WhitelistItems.HALF_PRICE_BUILD]) {
				fee = (fee * 50) / 100;
				whitelist[msg.sender][WhitelistItems.HALF_PRICE_BUILD] = false;
			}
			if (whitelist[msg.sender][WhitelistItems.FREE_BUILD]) {
				fee = 0;
				whitelist[msg.sender][WhitelistItems.FREE_BUILD] = false;
			}
			if (msg.value != fee) revert IncorrectValue();
		}

		_shields[tokenId] = Shield({
			field: field,
			hardware: hardware,
			frame: frame,
			colors: colors,
			shieldHash: newShieldHash,
			hardwareConfiguration: fullHardware
		});

		emit ShieldBuilt(
			msg.sender,
			tokenId,
			oldShield.shieldHash,
			newShieldHash,
			field,
			hardware,
			frame,
			colors
		);
	}

	// ============ PUBLIC VIEW FUNCTIONS ============

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		if (tokenId >= _currentId || tokenId == 0) revert InvalidShield();

		Shield memory shield = _shields[tokenId];

		if (shield.colors[0] != 0) {
			return emblemWeaver.generateShieldURI(shield);
		} else {
			return emblemWeaver.generateShieldPass();
		}
	}

	function totalSupply() public view returns (uint256) {
		unchecked {
			// starts with 1
			return _currentId - 1;
		}
	}

	function shields(uint256 tokenId)
		external
		view
		returns (
			uint16 field,
			uint16[9] memory hardware,
			uint16 frame,
			uint24 color1,
			uint24 color2,
			uint24 color3,
			uint24 color4
		)
	{
		Shield memory shield = _shields[tokenId];
		return (
			shield.field,
			shield.hardware,
			shield.frame,
			shield.colors[0],
			shield.colors[1],
			shield.colors[2],
			shield.colors[3]
		);
	}

	function priceInfo()
		external
		view
		returns (
			uint256 epicFieldFee_,
			uint256 heroicFieldFee_,
			uint256 olympicFieldFee_,
			uint256 legendaryFieldFee_,
			uint256 epicHardwareFee_,
			uint256 doubleHardwareFee_,
			uint256 multiHardwareFee_,
			uint256 adornedFrameFee_,
			uint256 menacingFrameFee_,
			uint256 securedFrameFee_,
			uint256 floriatedFrameFee_,
			uint256 everlastingFrameFee_
		)
	{
		return (
			epicFieldFee,
			heroicFieldFee,
			olympicFieldFee,
			legendaryFieldFee,
			epicHardwareFee,
			doubleHardwareFee,
			multiHardwareFee,
			adornedFrameFee,
			menacingFrameFee,
			securedFrameFee,
			floriatedFrameFee,
			everlastingFrameFee
		);
	}

	// ============ INTERNAL INTERFACE ============

	function calculateFieldFee(uint16 field, uint24[4] memory colors) internal returns (uint256 fee) {
		ICategories.FieldCategories fieldType = emblemWeaver
			.fieldGenerator()
			.generateField(field, colors)
			.fieldType;

		if (fieldType == ICategories.FieldCategories.EPIC) return epicFieldFee;

		if (fieldType == ICategories.FieldCategories.HEROIC) return heroicFieldFee;

		if (fieldType == ICategories.FieldCategories.OLYMPIC) return olympicFieldFee;

		if (fieldType == ICategories.FieldCategories.LEGENDARY) return legendaryFieldFee;
	}

	function calculateHardwareFee(uint16[9] memory hardware) internal returns (uint256 fee) {
		ICategories.HardwareCategories hardwareType = emblemWeaver
			.hardwareGenerator()
			.generateHardware(hardware)
			.hardwareType;

		if (hardwareType == ICategories.HardwareCategories.EPIC) return epicHardwareFee;

		if (hardwareType == ICategories.HardwareCategories.DOUBLE) return doubleHardwareFee;

		if (hardwareType == ICategories.HardwareCategories.MULTI) return multiHardwareFee;
	}

	function calculateFrameFee(uint16 frame) internal returns (uint256 fee) {
		ICategories.FrameCategories frameType = emblemWeaver
			.frameGenerator()
			.generateFrame(frame)
			.frameType;

		if (frameType == ICategories.FrameCategories.NONE) return 0;

		if (frameType == ICategories.FrameCategories.ADORNED) return adornedFrameFee;

		if (frameType == ICategories.FrameCategories.MENACING) return menacingFrameFee;

		if (frameType == ICategories.FrameCategories.SECURED) return securedFrameFee;

		if (frameType == ICategories.FrameCategories.FLORIATED) return floriatedFrameFee;

		if (frameType == ICategories.FrameCategories.EVERLASTING) return everlastingFrameFee;
	}

	function validateColors(uint24[4] memory colors, uint16 field) internal {
		if (field == 0) {
			checkExistsDupsMax(colors, 1);
		} else if (field <= 242) {
			checkExistsDupsMax(colors, 2);
		} else if (field <= 293) {
			checkExistsDupsMax(colors, 3);
		} else {
			checkExistsDupsMax(colors, 4);
		}
	}

	function checkExistsDupsMax(uint24[4] memory colors, uint8 nColors) private {
		for (uint8 i = 0; i < nColors; i++) {
			if (_checkDuplicateColors[colors[i]] == true) revert ColorError();
			if (!emblemWeaver.fieldGenerator().colorExists(colors[i])) revert ColorError();
			_checkDuplicateColors[colors[i]] = true;
		}
		for (uint8 i = 0; i < nColors; i++) {
			_checkDuplicateColors[colors[i]] = false;
		}
		for (uint8 i = nColors; i < 4; i++) {
			if (colors[i] != 0) revert ColorError();
		}
	}
}
