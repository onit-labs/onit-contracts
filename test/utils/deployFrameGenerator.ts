import { FrameGenerator, FrameSVGs1 } from '../../typechain'
import snapshotGasCost from './snapshotGasCost'

import { ethers } from 'hardhat'

export default async function deployFrameGenerator(asGasSnapshot?: boolean) {
	const frameSVGs1 = (await (await ethers.getContractFactory('FrameSVGs1')).deploy()) as FrameSVGs1
	await frameSVGs1.deployed()

	const frameSVGs2 = (await (await ethers.getContractFactory('FrameSVGs2')).deploy()) as FrameSVGs1
	await frameSVGs2.deployed()

	if (asGasSnapshot) {
		await snapshotGasCost(
			(
				await ethers.getContractFactory('FrameGenerator')
			).deploy({ frameSVGs1: frameSVGs1.address, frameSVGs2: frameSVGs2.address })
		)
	}

	const contract = (await (
		await ethers.getContractFactory('FrameGenerator')
	).deploy({ frameSVGs1: frameSVGs1.address, frameSVGs2: frameSVGs2.address })) as FrameGenerator
	await contract.deployed()

	return contract
}
