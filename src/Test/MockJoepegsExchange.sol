// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'hardhat/console.sol';

import {OrderTypes} from '../libraries/OrderTypes.sol';

import {IJoepegsExchange} from '../interfaces/IJoepegsExchange.sol';

contract MockJoepegsExchange is IJoepegsExchange {
	function matchAskWithTakerBidUsingETHAndWETH(
		OrderTypes.TakerOrder calldata takerBid,
		OrderTypes.MakerOrder calldata makerAsk
	) external payable {
		console.logString('matchAskWithTakerBidUsingETHAndWETH');
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
}
