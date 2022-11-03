import { FieldGenerator, FieldSVGs1, TestFieldGenerator } from '../../typechain'
import { fieldColors, titles } from './colors'
import snapshotGasCost from './snapshotGasCost'

import { deployments, ethers as hardhatEthers } from 'hardhat'
import { ethers } from 'hardhat'

export default async function deployTestFieldGenerator(asGasSnapshot?: boolean) {
	let [owner] = await hardhatEthers.getSigners()

	const fieldSVGs1 = (await (await ethers.getContractFactory('FieldSVGs1')).deploy()) as FieldSVGs1
	await fieldSVGs1.deployed()
	const fieldSVGs3 = (await (await ethers.getContractFactory('FieldSVGs3')).deploy()) as FieldSVGs1
	await fieldSVGs3.deployed()
	const fieldSVGs7 = (await (await ethers.getContractFactory('FieldSVGs7')).deploy()) as FieldSVGs1
	await fieldSVGs7.deployed()
	const fieldSVGs23 = (await (
		await ethers.getContractFactory('FieldSVGs23')
	).deploy()) as FieldSVGs1
	await fieldSVGs23.deployed()

	const svgs = {
		fieldSVGs1: fieldSVGs1.address,
		fieldSVGs3: fieldSVGs3.address,
		fieldSVGs7: fieldSVGs7.address,
		fieldSVGs23: fieldSVGs23.address
	}

	if (asGasSnapshot) {
		await snapshotGasCost(
			(await ethers.getContractFactory('TestFieldGenerator')).deploy(fieldColors, titles, svgs)
		)
	}

	const contract = (await (
		await ethers.getContractFactory('TestFieldGenerator')
	).deploy(owner.address, svgs)) as TestFieldGenerator
	await contract.deployed()

	return contract
}
