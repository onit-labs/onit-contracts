// Mostly SVG checking no expects are not always useful

/* eslint-disable jest/expect-expect */
import { fieldColors } from '../utils/colors'
import deployFrameGenerator from '../utils/deployFrameGenerator'
import deployTestFieldGenerator from '../utils/deployTestFieldGenerator'
import deployTestHardwareGenerator from '../utils/deployTestHardwareGenerator'
import encodeColors from '../utils/encodeColors'
import { expect } from '../utils/expect'
import { printSVGToSnapshots } from '../utils/printSVGToSnapshots'
import snapshotGasCost from '../utils/snapshotGasCost'

import {
	EmblemWeaverTest,
	FieldGenerator,
	FrameGenerator,
	HardwareGenerator,
	TestFieldGenerator,
	TestHardwareGenerator
} from '../../typechain'

import { BigNumberish } from 'ethers'
import { ethers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

interface hardwareItem {
	hardware: number
	position: number
}
// Deploying all 60 Contracts can be taxing for quick tests. Comment / Uncomment the
// Test and non test Hardware + Field if a full check of SVGs is needed
describe.skip('EmblemWeaver', () => {
	let emblemWeaver: EmblemWeaverTest
	let frameGenerator: FrameGenerator
	let fieldGenerator: FieldGenerator
	let hardwareGenerator: HardwareGenerator

	beforeEach(async () => {
		frameGenerator = (await deployFrameGenerator()) as FrameGenerator
		//hardwareGenerator = (await deployHardwareGenerator()) as HardwareGenerator
		//fieldGenerator = (await deployFieldGenerator()) as FieldGenerator
		hardwareGenerator = (await deployTestHardwareGenerator()) as TestHardwareGenerator
		fieldGenerator = (await deployTestFieldGenerator()) as TestFieldGenerator

		emblemWeaver = (await (
			await ethers.getContractFactory('EmblemWeaverTest')
		).deploy(
			fieldGenerator.address,
			hardwareGenerator.address,
			frameGenerator.address
		)) as EmblemWeaverTest
	})

	describe('constructor', () => {
		it('deployment gas', async () => {
			await snapshotGasCost(
				await (
					await ethers.getContractFactory('EmblemWeaver')
				).deploy(fieldGenerator.address, hardwareGenerator.address, frameGenerator.address)
			)
		})
		it('has bytecode size', async () => {
			expect(
				((await emblemWeaver.provider.getCode(emblemWeaver.address)).length - 2) / 2
			).to.matchSnapshot()
		})
	})

	describe('SVG generation', () => {
		let frame: number
		let field: number
		let hardware: any
		let shieldBadge: number
		let built: boolean
		let colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish]

		beforeEach(async () => {
			field = 1
			hardware = [1, 999, 2, 999, 999, 999, 999, 97, 999]
			frame = 0
			shieldBadge = 0
			built = true
			colors = encodeColors([...fieldColors])
		})

		it('all field SVGs deploy correctly', async () => {
			for (let i = 0; i <= 299; i++) {
				let j // write files with prepended 0's to keep numerical order (10's / 100's)
				if (i < 10) {
					j = `00${i}`
				} else if (i < 100) {
					j = `0${i}`
				} else {
					j = `${i}`
				}

				const shield = {
					field: i,
					hardware,
					frame,
					colors,
					shieldHash: ethers.utils.formatBytes32String(''),
					hardwareConfiguration: ethers.utils.formatBytes32String('')
				}
				const { svg, fieldTitle } = await emblemWeaver.generateSVGTest(shield)
				printSVGToSnapshots('fields', `${j}_${fieldTitle}`, svg)
			}
		})

		it('all hardware SVGs deploy correctly', async () => {
			for (let i = 0; i <= 120; i++) {
				let j // write files with prepended 0's to keep numerical order (10's / 100's)
				if (i < 10) {
					j = `00${i}`
				} else if (i < 100) {
					j = `0${i}`
				} else {
					j = `${i}`
				}

				const hwa: any = [i, i, i, i, i, i, i, i, i]

				const shield = {
					field,
					hardware: hwa,
					frame,
					colors,
					shieldHash: ethers.utils.formatBytes32String(''),
					hardwareConfiguration: ethers.utils.formatBytes32String('')
				}
				const { svg, hardwareTitle } = await emblemWeaver.generateSVGTest(shield)
				console.log({ svg })
				console.log({ hardwareTitle })

				printSVGToSnapshots('hardware', `${j}_${hardwareTitle}`, svg)
			}
		})

		it('all frame SVGs deploy correctly', async () => {
			for (let i = 0; i <= 5; i++) {
				let j // write files with prepended 0's to keep numerical order (10's / 100's)
				if (i < 10) {
					j = `00${i}`
				} else if (i < 100) {
					j = `0${i}`
				} else {
					j = `${i}`
				}

				const shield = {
					field,
					hardware,
					frame: i,
					colors,
					shieldHash: ethers.utils.formatBytes32String(''),
					hardwareConfiguration: ethers.utils.formatBytes32String('')
				}
				console.log({ shield })
				const { svg, frameTitle } = await emblemWeaver.generateSVGTest(shield)
				console.log({ svg })
				console.log({ frameTitle })

				printSVGToSnapshots('frames', `${j}_${frameTitle}`, svg)
			}
		})
	})
})
