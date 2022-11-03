/* eslint-disable prettier/prettier */
import { MakerOrder, MakerOrderWithSignature, TakerOrder } from './order-types'
import { signMakerOrder } from './signature-helper'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'

export interface SignedMakerOrder extends MakerOrder {
	signerUser: SignerWithAddress
	verifyingContract: string
}

export async function createMakerOrder({
	isOrderAsk,
	signer,
	collection,
	price,
	tokenId,
	amount,
	strategy,
	currency,
	nonce,
	startTime,
	endTime,
	minPercentageToAsk,
	params,
	signerUser,
	verifyingContract
}: SignedMakerOrder): Promise<MakerOrderWithSignature> {
	const makerOrder: MakerOrder = {
		isOrderAsk: isOrderAsk,
		signer: signer,
		collection: collection,
		price: price,
		tokenId: tokenId,
		amount: amount,
		strategy: strategy,
		currency: currency,
		nonce: nonce,
		startTime: startTime,
		endTime: endTime,
		minPercentageToAsk: minPercentageToAsk,
		params: params
	}

	const signedOrder = await signMakerOrder(signerUser, verifyingContract, makerOrder)

	// Extend makerOrder with proper signature
	const makerOrderExtended: MakerOrderWithSignature = {
		...makerOrder,
		r: signedOrder.r,
		s: signedOrder.s,
		v: signedOrder.v
	}

	return makerOrderExtended
}

export function createTakerOrder({
	isOrderAsk,
	taker,
	price,
	tokenId,
	minPercentageToAsk,
	params
}: TakerOrder): TakerOrder {
	const takerOrder: TakerOrder = {
		isOrderAsk: isOrderAsk,
		taker: taker,
		price: price,
		tokenId: tokenId,
		minPercentageToAsk: minPercentageToAsk,
		params: params
	}

	return takerOrder
}

export const orderHashTypes = [
	'bytes32',
	'bool',
	'address',
	'address',
	'uint256',
	'uint256',
	'uint256',
	'address',
	'address',
	'uint256',
	'uint256',
	'uint256',
	'uint256',
	'bytes32'
]

export const takerOrderTypes = ['bool', 'address', 'uint256', 'uint256', 'uint256', 'bytes']

export const makerOrderTypes = [
	'bool',
	'string',
	'string',
	'uint256',
	'uint256',
	'uint256',
	'string',
	'string',
	'uint256',
	'uint256',
	'uint256',
	'uint256',
	'bytes'
]
export const domainHashTypes = ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address']

export const testDomain1 = [
	'0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f',
	'0xda9101ba92939daf4bb2e18cd5f942363b9297fbc3232c9dd964abb1fb70ed71',
	'0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6',
	43113,
	'0x04e290be5163ad5c92109eb4733c45a2df110d44'
]

export const testMakerOrder1 = [
	'0x40261ade532fa1d2c7293df30aaadb9b3c616fae525a0b56d3d411c841a85028',
	true,
	'0xff626f22d92506b74eec6ccb15412e5a9d6a592d',
	'0x2995b185da8a77bc29933a59dbab973e23595139',
	'1',
	124,
	1,
	'0xdb9660c436dec824b379c59e2411c71f548f76a7',
	'0xd00ae08403b9bbb9124bb305c09058e32c39a48c',
	1,
	1658496979,
	1961088979,
	8500,
	'0x0000000000000000000000000000000000000000000000000000000000000000'
]
