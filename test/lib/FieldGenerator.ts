import { fieldColors, titles } from '../utils/colors'
import deployFieldGenerator from '../utils/deployFieldGenerator'
import encodeColors from '../utils/encodeColors'
import { expect } from '../utils/expect'
import snapshotGasCost from '../utils/snapshotGasCost'

import {
	colorsBatch2,
	colorsBatch3,
	colorsBatch4,
	titlesBatch2,
	titlesBatch3,
	titlesBatch4
} from '../../deploy/helpers'
import { FieldGenerator, FieldSVGs1 } from '../../typechain'

import { BigNumber, BigNumberish, Contract } from 'ethers'
import { deployments, ethers as hardhatEthers } from 'hardhat'

import fs = require('fs')

describe.skip('FieldSVGs', () => {
	let fieldSVGs1: FieldSVGs1
	let fieldGenerator: FieldGenerator

	beforeEach(async () => {
		// await deployments.fixture(['Forum'])
		// fieldGenerator = await hardhatEthers.getContract('FieldGenerator')
		fieldGenerator = await deployFieldGenerator()
	})

	describe('constructor', () => {
		it('deployment gas', async () => {
			const asGasSnapshot = true
			await deployFieldGenerator(asGasSnapshot)
		})

		it('bytecode size', async () => {
			const contract = await deployFieldGenerator()
			expect(((await contract.provider.getCode(contract.address)).length - 2) / 2).matchSnapshot()
		})

		it('Deploy and add second color batch', async () => {
			// batch1 color present, others not
			expect(await fieldGenerator.colorExists(0x000080)).equal(true)
			expect(await fieldGenerator.colorExists(0x6e0902)).equal(false)

			await fieldGenerator.addColors(colorsBatch2, titlesBatch2)
			expect(await fieldGenerator.colorExists(0x6e0902)).equal(true)

			await fieldGenerator.addColors(colorsBatch3, titlesBatch3)
			expect(await fieldGenerator.colorExists(0xca3435)).equal(true)

			await fieldGenerator.addColors(colorsBatch4, titlesBatch4)
			expect(await fieldGenerator.colorExists(0xffffff)).equal(true)
		})
	})

	describe.skip('IFieldSVGs deployment', () => {
		for (let i = 1; i <= 24; i++) {
			it(`FieldSVGs${i} has gas`, async () => {
				await snapshotGasCost((await hardhatEthers.getContractFactory(`FieldSVGs${i}`)).deploy())
			})

			it(`FieldSVGs${i} has bytecode`, async () => {
				const contract = await (await hardhatEthers.getContractFactory(`FieldSVGs${i}`)).deploy()
				expect(((await contract.provider.getCode(contract.address)).length - 2) / 2).matchSnapshot()
			})
		}
	})

	describe('SVG Generation', () => {
		beforeEach(async () => {
			// const fieldSVGs1 = (await (
			// 	await hardhatEthers.getContractFactory('FieldSVGs1')
			// ).deploy()) as FieldSVGs1
			// const fieldSVGs2 = (await (
			// 	await hardhatEthers.getContractFactory('FieldSVGs2')
			// ).deploy()) as FieldSVGs1
			// const contract = await (
			// 	await hardhatEthers.getContractFactory('FieldGenerator')
			// ).deploy(fieldColors, titles, fieldSVGs1.address, fieldSVGs2.address)
		})

		it('returns the correct field_one_color svg string', async () => {
			const color = encodeColors([fieldColors[0]])

			const svg = await fieldGenerator.generateField(0, color)
			expect(svg).toMatchSnapshot()
		})

		it('returns the correct field_two_colors svg string', async () => {
			const color = encodeColors([fieldColors[0], fieldColors[1]])

			const svg = await fieldGenerator.generateField(2, color)
			expect(svg).toMatchSnapshot()
		})

		it('returns the correct field_three_colors svg string', async () => {
			const color = encodeColors([fieldColors[0], fieldColors[1], fieldColors[2]])

			const svg = await fieldGenerator.generateField(293, color)
			expect(svg).toMatchSnapshot()
		})

		it('returns the correct field_four_colors svg string', async () => {
			const color = encodeColors([fieldColors[0], fieldColors[1], fieldColors[2], fieldColors[3]])

			const svg = await fieldGenerator.generateField(299, color)
			expect(svg).toMatchSnapshot()
		})
	})
})
