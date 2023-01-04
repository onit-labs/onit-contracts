// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'hardhat/console.sol';

import {OrderTypes} from '../libraries/OrderTypes.sol';

import {ICrowdfundExecutionHandler} from '../interfaces/ICrowdfundExecutionHandler.sol';
import {IJoepegsExchange} from '../interfaces/IJoepegsExchange.sol';
import {ERC721Test} from '../test-contracts/ERC721Test.sol';

/// @dev THIS IS A TESTING CONTRACT ONLY
/// We simiulate a buy on joepegs by minting a token and sending it to the buyer
contract MockJoepegsExchange is IJoepegsExchange {
	address public test721;

	constructor(address _test721) {
		test721 = _test721;
	}

	function matchAskWithTakerBidUsingAVAXAndWAVAX(
		OrderTypes.TakerOrder calldata takerBid,
		OrderTypes.MakerOrder calldata makerAsk
	) external payable {
		console.logString('matchAskWithTakerBidUsingETHAndWETH');

		// Simulates the result of a buy on joepegs
		ERC721Test(test721).mint(takerBid.taker, takerBid.tokenId);
	}

	function matchAskWithTakerBid(
		OrderTypes.TakerOrder calldata takerBid,
		OrderTypes.MakerOrder calldata makerAsk
	) external {
		console.logString('matchAskWithTakerBid');
	}

	function matchBidWithTakerAsk(
		OrderTypes.TakerOrder calldata takerAsk,
		OrderTypes.MakerOrder calldata makerBid
	) external {
		console.logString('matchBidWithTakerAsk');
	}

	receive() external payable virtual {}
}
