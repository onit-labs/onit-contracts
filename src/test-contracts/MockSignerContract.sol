// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Owned} from '../utils/Owned.sol';

import {IERC1271} from '@openzeppelin/contracts/interfaces/IERC1271.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721Holder} from '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import 'hardhat/console.sol';

struct MakerOrder {
	bool isOrderAsk; // true --> ask / false --> bid
	address signer; // signer of the maker order
	address collection; // collection address
	uint256 price; // price (used as )
	uint256 tokenId; // id of the token
	uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
	address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
	address currency; // currency (e.g., WETH)
	uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
	uint256 startTime; // startTime in timestamp
	uint256 endTime; // endTime in timestamp
	uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
	bytes params; // additional parameters
	uint8 v; // v: parameter (27 or 28)
	bytes32 r; // r: parameter
	bytes32 s; // s: parameter
}

contract MockSignerContract is IERC1271, ERC721Holder, Owned {
	bytes32 internal constant MAKER_ORDER_HASH =
		0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028;
	// bytes4(keccak256("isValidSignature(bytes32,bytes)")
	bytes4 internal constant MAGICVALUE = 0x1626ba7e;

	bytes32 DOMAIN_SEPARATOR =
		keccak256(
			abi.encode(
				0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
				0xda9101ba92939daf4bb2e18cd5f942363b9297fbc3232c9dd964abb1fb70ed71, // keccak256("LooksRareExchange")
				0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
				block.chainid,
				address(this)
			)
		);

	constructor(address _owner) public Owned(_owner) {}

	/**
	 * @notice Approve ERC20
	 */
	function approveERC20ToBeSpent(address token, address target) external onlyOwner {
		IERC20(token).approve(target, type(uint256).max);
	}

	/**
	 * @notice Approve all ERC721 tokens
	 */
	function approveERC721NFT(address collection, address target) external onlyOwner {
		IERC721(collection).setApprovalForAll(target, true);
	}

	/**
	 * @notice Withdraw ERC20 balance
	 */
	function withdrawERC20(address token) external onlyOwner {
		IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
	}

	/**
	 * @notice Withdraw ERC721 tokenId
	 */
	function withdrawERC721NFT(address collection, uint256 tokenId) external onlyOwner {
		IERC721(collection).transferFrom(address(this), msg.sender, tokenId);
	}

	// TESTING - From Looksrare: function to mimic hashing
	function hash(MakerOrder memory makerOrder) public pure returns (bytes32) {
		return
			keccak256(
				abi.encode(
					MAKER_ORDER_HASH,
					makerOrder.isOrderAsk,
					makerOrder.signer,
					makerOrder.collection,
					makerOrder.price,
					makerOrder.tokenId,
					makerOrder.amount,
					makerOrder.strategy,
					makerOrder.currency,
					makerOrder.nonce,
					makerOrder.startTime,
					makerOrder.endTime,
					makerOrder.minPercentageToAsk,
					keccak256(makerOrder.params)
				)
			);
	}

	/**
	 * @notice TESTING - From Looksrare: Verify the validity of the maker order
	 * @param makerOrder maker order
	 * @param orderHash computed hash for the order
	 */
	function _validateOrder(
		MakerOrder calldata makerOrder,
		bytes32 orderHash,
		address groupWallet
	) public view {
		// Verify the signer is not address(0)
		require(makerOrder.signer != address(0), 'Order: Invalid signer');

		// Verify the amount is not 0
		require(makerOrder.amount > 0, 'Order: Amount cannot be 0');

		// Verify the validity of the signature
		require(
			verify(
				groupWallet,
				orderHash,
				//makerOrder.signer,
				makerOrder.v,
				makerOrder.r,
				makerOrder.s,
				DOMAIN_SEPARATOR
			),
			'Signature: Invalid'
		);
	}

	//TESTING - From Looksrare: Similate digest to be used to set in the multisig as an allowed signature
	function digest(bytes32 orderHash) public view returns (bytes32 orderDigest) {
		// \x19\x01 is the standardized encoding prefix
		// https://eips.ethereum.org/EIPS/eip-712#specification
		orderDigest = keccak256(abi.encodePacked('\x19\x01', DOMAIN_SEPARATOR, orderHash));

		return orderDigest;
	}

	// TESTING - From Looksrare: Simulate the verify function
	// groupWallet added to simplify the test
	// signer commented as it is not used but we keep the full signature visible for reference
	function verify(
		address groupWallet,
		bytes32 orderHash,
		//address signer,
		uint8 v,
		bytes32 r,
		bytes32 s,
		bytes32 domainSeparator
	) public view returns (bool) {
		// \x19\x01 is the standardized encoding prefix
		// https://eips.ethereum.org/EIPS/eip-712#specification
		//bytes32 digest_ = keccak256(abi.encodePacked('\x19\x01', domainSeparator, orderHash));
		bytes32 digest_ = digest(orderHash);
		// 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
		return IERC1271(groupWallet).isValidSignature(digest_, abi.encodePacked(r, s, v)) == 0x1626ba7e;
	}

	/**
	 * @notice Verifies that the signer is the owner of the signing contract.
	 * FOR TESTING ONLY
	 */
	function isValidSignature(bytes32 approvedHash, bytes memory signature)
		external
		view
		override
		returns (bytes4)
	{
		require(signature.length == 65, 'SignatureValidator: Invalid signature length');

		uint8 v;
		bytes32 r;
		bytes32 s;

		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := and(mload(add(signature, 65)), 255)
		}

		require(
			uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
			'Signature: Invalid S parameter'
		);

		require(v == 27 || v == 28, 'Signature: Invalid V parameter');

		// If the signature is valid (and not malleable), return the signer address
		address signer = ecrecover(approvedHash, v, r, s);
		require(signer != address(0), 'Signature: Invalid signer');

		if (signer == owner) {
			return MAGICVALUE;
		} else {
			return 0xffffffff;
		}
	}
}
