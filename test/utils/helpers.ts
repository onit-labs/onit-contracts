import { BigNumber } from 'ethers'
import { ethers, ethers as hardhatEthers } from 'hardhat'

export function getBigNumber(amount: number, decimals = 18) {
	const isFraction = amount % 1 !== 0

	// crude method to deal with the decimals we expect in this set of tests
	if (isFraction) {
		amount = amount * 10 ** 4
		decimals = decimals - 4
	}

	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals))
}

export async function advanceTime(time: number) {
	await hardhatEthers.provider.send('evm_increaseTime', [time])
}

export const parseEther = (amount: string) => {
	return BigNumber.from(hardhatEthers.utils.parseEther(amount))
}

export function padString(s: string) {
	if (s.length < 3)
		for (let i = 0; i <= 3 - s.length; i++) {
			s = '0' + s
		}
	return s
}

export function formatHardware(hardware: number[]) {
	let fullHardware = ''
	for (let i = 0; i < 9; i++) {
		console.log(hardware[i].toString())
		fullHardware = fullHardware + padString(hardware[i].toString())
	}
	return fullHardware
}

export function web3StringToBytes32(text) {
	let result = ethers.utils.hexlify(ethers.utils.toUtf8Bytes(text))
	while (result.length < 66) {
		result += '0'
	}
	if (result.length !== 66) {
		throw new Error('invalid web3 implicit bytes32')
	}
	return result
}

// Packs an array of uint16 into a single uint256
export function packTargetMethods(targetMethods: number[]) {
	let count = 16
	let formattedTargetMethods = BigInt(targetMethods[0])
	console.log(formattedTargetMethods)

	for (let i = 1; i < targetMethods.length; i++) {
		formattedTargetMethods |= BigInt(targetMethods[i]) << BigInt(count)
		console.log(targetMethods[i])
		console.log(formattedTargetMethods)
		count += 16
	}
	return formattedTargetMethods
}

export function functionSelector(functionSig: string): string {
	return ethers.utils.keccak256(ethers.utils.toUtf8Bytes(functionSig))
}
