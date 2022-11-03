import { HardwareSVGs1, TestHardwareGenerator } from '../../typechain'
import snapshotGasCost from './snapshotGasCost'

import { ethers } from 'hardhat'

export default async function deployTestHardwareGenerator(asGasSnapshot?: boolean) {
	const hardwareSVGs1 = (await (
		await ethers.getContractFactory('HardwareSVGs1')
	).deploy()) as HardwareSVGs1
	await hardwareSVGs1.deployed()

	const hardwareSVGs29 = (await (
		await ethers.getContractFactory('HardwareSVGs29')
	).deploy()) as HardwareSVGs1
	await hardwareSVGs29.deployed()

	const svgs = {
		hardwareSVGs1: hardwareSVGs1.address,
		hardwareSVGs29: hardwareSVGs29.address
	}

	if (asGasSnapshot) {
		await snapshotGasCost((await ethers.getContractFactory('TestHardwareGenerator')).deploy(svgs))
	}

	const contract = (await (
		await ethers.getContractFactory('TestHardwareGenerator')
	).deploy(svgs)) as TestHardwareGenerator
	await contract.deployed()

	return contract
}
