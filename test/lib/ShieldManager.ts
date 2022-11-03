/* eslint-disable no-unexpected-multiline */

/* eslint-disable jest/valid-expect */

/* eslint-disable jest/no-disabled-tests */

/* eslint-disable jest/no-commented-out-tests */
import { buildShield } from '../utils/buildShield'
import { fieldColors, titles } from '../utils/colors'
import deployFieldGenerator from '../utils/deployFieldGenerator'
import deployFrameGenerator from '../utils/deployFrameGenerator'
import deployHardwareGenerator from '../utils/deployHardwareGenerator'
import deployTestFieldGenerator from '../utils/deployTestFieldGenerator'
import deployTestHardwareGenerator from '../utils/deployTestHardwareGenerator'
import encodeColors from '../utils/encodeColors'
// import deployTestHardwareGenerator from '../utils/deployTestHardwareGenerator'
import { expect } from '../utils/expect'
import { extractJSONFromURI } from '../utils/extractJSONFromURI'
import { getBigNumber } from '../utils/helpers'
import snapshotGasCost from '../utils/snapshotGasCost'

import {
	AccessManager,
	EmblemWeaver,
	EmblemWeaverTest,
	FieldGenerator,
	FrameGenerator,
	HardwareGenerator,
	PfpStaker,
	ShieldManager,
	ShieldsGasTest,
	TestFieldGenerator,
	TestHardwareGenerator
} from '../../typechain'
import {
	ADORNED_FRAME,
	ADORNED_FRAME_FEE,
	BASIC_ACCESS,
	BASIC_ACCESS_ITEM,
	BASIC_FIELD,
	BASIC_HARDWARE,
	BRONZE_ACCESS,
	BRONZE_ACCESS_ITEM,
	BRONZE_SVG,
	colorList,
	DOUBLE_HARDWARE,
	DOUBLE_HARDWARE_FEE,
	EPIC_FIELD,
	EPIC_FIELD_FEE,
	EPIC_HARDWARE,
	EPIC_HARDWARE_FEE,
	EVERLASTING_FRAME,
	EVERLASTING_FRAME_FEE,
	EXPECTED_SHILED_PASS,
	expectedFieldFeesBasic,
	expectedFieldFeesBronze,
	expectedFieldFeesGold,
	expectedFieldFeesSilver,
	expectedFrameFeesBasic,
	expectedFrameFeesBronze,
	expectedFrameFeesGold,
	expectedFrameFeesSilver,
	expectedHardwareFeesBasic,
	expectedHardwareFeesBronze,
	expectedHardwareFeesGold,
	expectedHardwareFeesSilver,
	FLORATED_FRAME,
	FLORATED_FRAME_FEE,
	FREE_BUILD,
	GOLD_ACCESS,
	GOLD_ACCESS_ITEM,
	HALF_PRICE_BUILD,
	HEROIC_FIELD,
	HEROIC_FIELD_FEE,
	INVALID_MULTI_1,
	INVALID_MULTI_2,
	LEGENDARY_FIELD,
	LEGENDARY_FIELD_FEE,
	MENACING_FRAME,
	MENACING_FRAME_FEE,
	MINT_FEE,
	MINT_SHIELD_PASS,
	MULTI_HARDWARE,
	MULTI_HARDWARE_FEE,
	NO_ACCESS,
	NO_FRAME,
	OLYMPIC_FIELD,
	OLYMPIC_FIELD_FEE,
	SECURED_FRAME,
	SECURED_FRAME_FEE,
	SILVER_ACCESS,
	SILVER_ACCESS_ITEM,
	SILVER_SVG,
	ZERO_ADDRESS
} from '../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber, BigNumberish } from 'ethers'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

import chai = require('chai')

chai.should()

describe.skip('Shields', function () {
	let owner: SignerWithAddress
	let factory: SignerWithAddress
	let roundtable1: SignerWithAddress
	let roundtable2: SignerWithAddress
	let alice: SignerWithAddress
	let bob: SignerWithAddress
	let carol: SignerWithAddress
	let emblemWeaver: EmblemWeaver
	let frameGenerator: FrameGenerator
	let fieldGenerator: FieldGenerator
	let hardwareGenerator: TestHardwareGenerator
	// let hardwareGenerator: HardwareGenerator
	let shieldManager: ShieldManager
	let accessManager: AccessManager
	let pfpStaker: PfpStaker
	let tokenId: number

	beforeEach(async () => {
		// let wallets: any
		;[owner, factory, roundtable1, roundtable2, alice, bob, carol] =
			await hardhatEthers.getSigners()

		await deployments.fixture(['Roundtable'])
		// fieldGenerator = await ethers.getContract('FieldGenerator')
		// hardwareGenerator = await ethers.getContract('HardwareGenerator')
		// frameGenerator = await ethers.getContract('FrameGenerator')
		// emblemWeaver = await ethers.getContract('EmblemWeaver')
		accessManager = await hardhatEthers.getContract('AccessManager')
		pfpStaker = await hardhatEthers.getContract('PfpStaker')

		// The below production of shieldManager and emblemWeaver should be raplaced by the above when the deployments are corrected to take the SVGs on hardhat
		// ////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////

		frameGenerator = (await deployFrameGenerator()) as FrameGenerator
		// hardwareGenerator = (await deployHardwareGenerator()) as HardwareGenerator
		// fieldGenerator = (await deployFieldGenerator()) as FieldGenerator
		hardwareGenerator = (await deployTestHardwareGenerator()) as TestHardwareGenerator
		fieldGenerator = (await deployTestFieldGenerator()) as TestFieldGenerator

		await fieldGenerator.addColors(fieldColors, titles)

		emblemWeaver = (await (
			await hardhatEthers.getContractFactory('EmblemWeaver')
		).deploy(
			fieldGenerator.address,
			hardwareGenerator.address,
			frameGenerator.address
		)) as EmblemWeaver

		shieldManager = (await (
			await hardhatEthers.getContractFactory('ShieldManager')
		).deploy(owner.address, 'Shields', 'SHIELDS', emblemWeaver.address)) as ShieldManager

		// ////////////////////////////////////////////////////////////////
		// ////////////////////////////////////////////////////////////////

		await shieldManager.connect(owner).setPublicMintActive(true)
	})

	describe('Constructor & Setup', () => {
		// eslint-disable-next-line jest/expect-expect
		it('deployment gas', async () => {
			await snapshotGasCost(
				await (
					await hardhatEthers.getContractFactory('ShieldManager')
				).deploy(owner.address, 'Shields', 'SHIELDS', emblemWeaver.address)
			)
		})

		// it('has bytecode size', async () => {
		// 	expect(((await shieldManager.provider.getCode(shieldManager.address)).length - 2) / 2).matchSnapshot()
		// })

		// it('initializes', async () => {
		// 	expect(await shieldManager.name()).equal('Shields')
		// 	expect(await shieldManager.symbol()).equal('SHIELDS')
		// })
	})

	describe('Admin', () => {
		// eslint-disable-next-line jest/expect-expect
		it('sets prelaunch supply', async () => {
			// Set field prices for each of the field types
			await shieldManager.setPreLaunchSupply(1)
			expect(await shieldManager.preLaunchSupply()).equal(1)
		})
		it('sets distribution', async () => {
			// Set field prices for each of the field types
			await shieldManager.setShieldItemPrices(
				[getBigNumber(5), getBigNumber(5), getBigNumber(5), getBigNumber(5)],
				[],
				[]
			)
			let priceInfo = await shieldManager.priceInfo()
			expect(priceInfo[0]).equal(getBigNumber(5))
			expect(priceInfo[1]).equal(getBigNumber(5))
			expect(priceInfo[2]).equal(getBigNumber(5))
			expect(priceInfo[3]).equal(getBigNumber(5))

			// Set hardware prices
			await shieldManager.setShieldItemPrices(
				[],
				[getBigNumber(5), getBigNumber(5), getBigNumber(5)],
				[]
			)
			priceInfo = await shieldManager.priceInfo()
			expect(priceInfo[4]).equal(getBigNumber(5))
			expect(priceInfo[5]).equal(getBigNumber(5))
			expect(priceInfo[6]).equal(getBigNumber(5))

			// Set frame prices
			await shieldManager.setShieldItemPrices(
				[],
				[],
				[getBigNumber(5), getBigNumber(5), getBigNumber(5), getBigNumber(5), getBigNumber(5)]
			)
			priceInfo = await shieldManager.priceInfo()
			expect(priceInfo[7]).equal(getBigNumber(5))
			expect(priceInfo[8]).equal(getBigNumber(5))
			expect(priceInfo[9]).equal(getBigNumber(5))
			expect(priceInfo[10]).equal(getBigNumber(5))
			expect(priceInfo[11]).equal(getBigNumber(5))
		})
		it('builds and transfers a batch of shields', async () => {
			// Allows for relayed building of shields from owner
			await shieldManager.setRoundtableRelay(owner.address)

			await shieldManager.buildAndDropShields(
				[alice.address, bob.address, carol.address, owner.address],
				[
					{
						field: 0,
						hardware: [999, 999, 999, 999, 2, 999, 999, 999, 999],
						frame: 0,
						colors: encodeColors(colorList[0]),
						shieldHash: hardhatEthers.utils.formatBytes32String(''),
						hardwareConfiguration: hardhatEthers.utils.formatBytes32String('')
					},
					{
						field: 0,
						hardware: [999, 999, 999, 999, 3, 999, 999, 999, 999],
						frame: ADORNED_FRAME,
						colors: encodeColors(colorList[0]),
						shieldHash: hardhatEthers.utils.formatBytes32String(''),
						hardwareConfiguration: hardhatEthers.utils.formatBytes32String('')
					},
					{
						field: 0,
						hardware: [999, 999, 999, 999, 4, 999, 999, 999, 999],
						frame: MENACING_FRAME,
						colors: encodeColors(colorList[0]),
						shieldHash: hardhatEthers.utils.formatBytes32String(''),
						hardwareConfiguration: hardhatEthers.utils.formatBytes32String('')
					},
					{
						field: 0,
						hardware: [999, 999, 999, 999, 5, 999, 999, 999, 999],
						frame: SECURED_FRAME,
						colors: encodeColors(colorList[0]),
						shieldHash: hardhatEthers.utils.formatBytes32String(''),
						hardwareConfiguration: hardhatEthers.utils.formatBytes32String('')
					}
				]
			)

			// Check details of shields and owners after drop
			expect((await shieldManager.shields(1)).frame).equal(NO_FRAME)
			expect(await shieldManager.ownerOf(1)).equal(alice.address)
			expect((await shieldManager.shields(2)).frame).equal(ADORNED_FRAME)
			expect(await shieldManager.ownerOf(2)).equal(bob.address)
			expect((await shieldManager.shields(3)).frame).equal(MENACING_FRAME)
			expect(await shieldManager.ownerOf(3)).equal(carol.address)
		})
	})

	describe('Mint Shield Pass', () => {
		// eslint-disable-next-line jest/expect-expect
		it('mints a load', async () => {
			const [owner, wallet, alice, bob, carol, d, e, f, g, h, i, j, k, l, m, n, o] =
				await hardhatEthers.getSigners()
			for (const member of [bob, carol, d, e, f, g, h, i, j, k, l]) {
				await shieldManager.mintShieldPass(member.address, { value: MINT_FEE })
			}
		})
		it('checks output tokenURI for non built shield', async () => {
			const tx = await (
				await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			).wait()
			const tokenId = parseInt(tx.events?.[0].args?.tokenId)

			expect(await shieldManager.tokenURI(tokenId)).equal(EXPECTED_SHILED_PASS)
		})
		it('prevents mint if public mint not active', async () => {
			await shieldManager.connect(owner).setPublicMintActive(false)
			await expect(shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })).revertedWith(
				'MintingClosed()'
			)
		})
		it('prevents setting public mint active if not owner', async () => {
			await expect(shieldManager.connect(alice).setPublicMintActive(true)).revertedWith(
				'UNAUTHORIZED'
			)
		})
		it('sets public mint active', async () => {
			await shieldManager.connect(owner).setPublicMintActive(true)
			expect(await shieldManager.publicMintActive()).equal(true)
		})
		it('prevents mint if fee not paid', async () => {
			await expect(shieldManager.mintShieldPass(alice.address)).revertedWith('IncorrectValue()')
		})
		it('prevents mint if pre launch and not on WL', async () => {
			// Ensure there is no supply so only WL can mint
			await shieldManager.connect(owner).setPublicMintActive(false)
			await shieldManager.setPreLaunchSupply(0)

			await expect(shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })).revertedWith(
				'MintingClosed()'
			)
		})
		it('mints if pre launch and on WL', async () => {
			// Ensure there is no supply so only WL can mint
			await shieldManager.connect(owner).setPublicMintActive(false)
			await shieldManager.setPreLaunchSupply(0)

			await shieldManager.toggleItemWhitelist(alice.address, MINT_SHIELD_PASS)
			console.log(await shieldManager.whitelist(alice.address, MINT_SHIELD_PASS))

			expect(await shieldManager.whitelist(alice.address, MINT_SHIELD_PASS)).equal(true)
			await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			expect(await shieldManager.balanceOf(alice.address)).equal(1)
		})
	})

	// In the below tests ['safeTransferFrom(address,address,uint256)'] is added to the calls since 2
	// functions share the same name in the ERC721 contract. This is just for testing and does not
	// effect the functionality of the contract.
	describe('Transfer Shield', () => {
		let tokenId2
		beforeEach(async () => {
			// await shieldManager.setRoundtableFactory(factory.address)

			const tx = await (
				await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			).wait()
			tokenId = parseInt(tx.events?.[0].args?.tokenId)

			await buildShield(shieldManager.connect(alice), {
				field: BASIC_FIELD,
				hardware: BASIC_HARDWARE,
				frame: NO_FRAME,
				colors: encodeColors([fieldColors[0]]),
				fee: getBigNumber(0),
				tokenId: tokenId
				// to
			})
		})
		it('transfers a built shield and checks details', async () => {
			expect(await shieldManager.ownerOf(tokenId)).equal(alice.address)

			// check details of shield 1
			const shield = await shieldManager.shields(tokenId)
			expect(shield.field).equal(BASIC_FIELD)
			expect(shield.hardware).deep.equal(BASIC_HARDWARE)
			expect(shield.color1).equal(fieldColors[0])
			expect(shield.color3).equal(0)

			// tranfer alice shield to bob
			await shieldManager
				.connect(alice)
				['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, tokenId)
			expect(await shieldManager.ownerOf(tokenId)).equal(bob.address)
		})
		it('prevents transfer if not owner or approved', async () => {
			await expect(
				shieldManager
					.connect(bob)
					['safeTransferFrom(address,address,uint256)'](alice.address, alice.address, tokenId)
			).revertedWith('NotApproved()')
		})
		it('prevents transfer if "from" doesnt match tokenId', async () => {
			await expect(
				shieldManager
					.connect(bob)
					['safeTransferFrom(address,address,uint256)'](bob.address, alice.address, tokenId)
			).revertedWith('NotTokenOwner()')
		})
		it('transfers if approval for all', async () => {
			await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			await shieldManager.connect(alice).setApprovalForAll(bob.address, true)

			// bob can transfer each of alices tokens
			await shieldManager
				.connect(bob)
				['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, tokenId)
			await shieldManager
				.connect(bob)
				['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, tokenId + 1)

			expect(await shieldManager.ownerOf(tokenId)).equal(bob.address)
			expect(await shieldManager.ownerOf(tokenId + 1)).equal(bob.address)
		})
		it('transfers if approved for specific', async () => {
			await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			await shieldManager.connect(alice).approve(bob.address, tokenId)

			await shieldManager
				.connect(bob)
				['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, tokenId)
			expect(await shieldManager.ownerOf(tokenId)).equal(bob.address)

			await expect(
				shieldManager
					.connect(bob)
					['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, tokenId + 1)
			).revertedWith('NotApproved()')
		})
		it('transfers with normal transferFrom', async () => {
			// bob can transfer each of alices tokens
			await shieldManager
				.connect(alice)
				['safeTransferFrom(address,address,uint256)'](alice.address, bob.address, tokenId)
			expect(await shieldManager.ownerOf(tokenId)).equal(bob.address)
		})
	})

	// describe.skip('collectFees', () => {
	// 	beforeEach(async () => {
	// 		await shieldManager.connect(owner).setShieldPassPrice(MINT_FEE)
	// 		await shieldManager.connect(owner).setPublicMintActive()
	// 	})

	// 	it('sends ether balance to the contract owner', async () => {
	// 		// build shield to send fee
	// 		const field = EPIC_FIELD
	// 		const hardware = EPIC_HARDWARE
	// 		const colors = encodeColors([fieldColors[0]])
	// 		const frame = 0
	// 		const fee = MYTHIC_FEE.add(SPECIAL_FEE)
	// 		const to = wallet.address

	// 		await buildShield(shieldManager.connect(wallet).connect(wallet), {
	// 			field,
	// 			hardware,
	// 			frame,
	// 			colors,
	// 			fee,
	// 			to
	// 		})

	// 		const shieldManagerBalancePrevious = await waffle.provider.getBalance(shieldManager.address)
	// 		const ownerBalancePrevious = await waffle.provider.getBalance(owner.address)

	// 		await shieldManager.connect(owner).collectFees()

	// 		const shieldManagerBalanceUpdated = await waffle.provider.getBalance(shieldManager.address)
	// 		const ownerBalanceUpdated = await waffle.provider.getBalance(owner.address)

	// 		expect(shieldManagerBalancePrevious.sub(shieldManagerBalanceUpdated)).equal(
	// 			MINT_FEE.add(fee)
	// 		)
	// 		expect(ownerBalanceUpdated.gt(ownerBalancePrevious))
	// 	})

	// 	it('reverts when called by non-owner address', async () => {
	// 		const field = BASIC_FIELD
	// 		const hardware = BASIC_HARDWARE
	// 		const colors = encodeColors([fieldColors[0], fieldColors[3]])
	// 		const frame = 0
	// 		const fee = BigNumber.from(0)
	// 		const to = wallet.address

	// 		await buildShield(shieldManager.connect(wallet).connect(wallet), {
	// 			field,
	// 			hardware,
	// 			frame,
	// 			colors,
	// 			fee,
	// 			to
	// 		})

	// 		await expect(shieldManager.connect(wallet).collectFees()).revertedWith(
	// 			'Ownable: caller is not the owner'
	// 		)
	// 	})
	// })

	// // ---------------------------------------------------------------------------------------------------
	// // Build
	// // ---------------------------------------------------------------------------------------------------

	// TODO add tests for WL builds
	describe('Build', () => {
		let frame: number
		let field: number
		let hardware: number[]
		let colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish]
		let fee: BigNumber
		let tokenId: BigNumberish

		beforeEach(async () => {
			field = BASIC_FIELD
			hardware = BASIC_HARDWARE
			frame = 0
			colors = encodeColors([fieldColors[0]])
			fee = BigNumber.from(0)

			// await accessManager.connect(owner).setShieldManager(shieldManager.address)

			const tx = await (
				await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			).wait()
			tokenId = parseInt(tx.events?.[0].args?.tokenId)
			console.log('tokenId', tokenId)
		})
		// eslint-disable-next-line jest/expect-expect
		it('gas build simple shield', async () => {
			console.log('tokenId', tokenId)

			await snapshotGasCost(
				(
					await buildShield(shieldManager.connect(alice), {
						field,
						hardware,
						frame,
						colors,
						fee,
						tokenId
					})
				).tx
			)
		})
		// eslint-disable-next-line jest/expect-expect
		it('gas build medium shield', async () => {
			console.log('tokenId', tokenId)

			await snapshotGasCost(
				(
					await buildShield(shieldManager.connect(alice), {
						field,
						hardware: [97, 999, 97, 999, 999, 999, 999, 1, 999],
						frame: SECURED_FRAME,
						colors,
						fee: fee.add(SECURED_FRAME_FEE).add(MULTI_HARDWARE_FEE),
						tokenId
					})
				).tx
			)

			const shield = await shieldManager.shields(tokenId)
			expect(shield.field).equal(field)
			expect(shield.field).equal(field)
			expect(shield.hardware).deep.equal([97, 999, 97, 999, 999, 999, 999, 1, 999])
			expect(shield.frame).equal(SECURED_FRAME)
		})
		// eslint-disable-next-line jest/expect-expect
		it('gas build more complex shield', async () => {
			field = HEROIC_FIELD
			hardware = MULTI_HARDWARE
			colors = encodeColors([fieldColors[0], fieldColors[1], fieldColors[2], fieldColors[3]])
			fee = BigNumber.from(HEROIC_FIELD_FEE).add(MULTI_HARDWARE_FEE).add(EVERLASTING_FRAME_FEE)
			await snapshotGasCost(
				(
					await buildShield(shieldManager.connect(alice), {
						field,
						hardware: [97, 97, 97, 97, 97, 97, 97, 97, 97],
						frame: EVERLASTING_FRAME,
						colors,
						fee,
						tokenId
					})
				).tx
			)
		})
		it('pulls the build fee into the shieldManager contract', async () => {
			field = HEROIC_FIELD
			hardware = EPIC_HARDWARE
			colors = encodeColors([fieldColors[0], fieldColors[1], fieldColors[2], fieldColors[3]])
			fee = HEROIC_FIELD_FEE.add(EPIC_HARDWARE_FEE)
			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)

			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee,
				tokenId
			})

			const shieldManagerBalanceUpdated = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			expect(shieldManagerBalanceUpdated.sub(shieldManagerBalancePrevious)).equal(fee)
		})
		it('reverts if shield already built', async () => {
			field = EPIC_FIELD
			hardware = EPIC_HARDWARE
			colors = encodeColors([fieldColors[0], fieldColors[1]])
			fee = EPIC_FIELD_FEE

			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee: fee.add(EPIC_HARDWARE_FEE),
				tokenId
			})

			await expect(
				buildShield(shieldManager.connect(alice), {
					field,
					hardware,
					frame,
					colors,
					fee: fee.add(EPIC_HARDWARE_FEE),
					tokenId
				})
			).revertedWith('DuplicateShield()')
		})
		it.skip('reverts if owner doesnt match tokenId', async () => {
			field = EPIC_FIELD
			hardware = EPIC_HARDWARE
			colors = encodeColors([fieldColors[0], fieldColors[1]])
			fee = EPIC_FIELD_FEE

			await expect(
				buildShield(shieldManager.connect(bob), {
					field,
					hardware,
					frame,
					colors,
					fee,
					tokenId
				})
			).revertedWith('Unauthorised()')
		})
		it('reverts with insufficient build fee', async () => {
			field = EPIC_FIELD
			hardware = EPIC_HARDWARE
			colors = encodeColors([fieldColors[0], fieldColors[1]])
			fee = EPIC_FIELD_FEE

			await expect(
				buildShield(shieldManager.connect(alice), {
					field,
					hardware,
					frame,
					colors,
					fee,
					tokenId
				})
			).revertedWith('IncorrectValue()')
		})
		it('reverts if a duplicate shield is built', async () => {
			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee,
				tokenId
			})

			const tx = await (await shieldManager.mintShieldPass(bob.address, { value: MINT_FEE })).wait()
			tokenId = parseInt(tx.events?.[0].args?.tokenId)

			await expect(
				buildShield(shieldManager.connect(bob), {
					field,
					hardware,
					frame,
					colors,
					fee,
					tokenId
				})
			).revertedWith('DuplicateShield()')
		})
		it('reverts if there are duplicate colors', async () => {
			field = 2
			colors = encodeColors([fieldColors[0], fieldColors[0], 0, 0])
			fee = BigNumber.from(0)
			await expect(
				buildShield(shieldManager.connect(alice), {
					field,
					hardware,
					frame,
					colors,
					fee,
					tokenId
				})
			).revertedWith('ColorError()')
		})
		it('reverts if there are too many colors defined for the given field', async () => {
			field = 2
			colors = encodeColors([fieldColors[0], fieldColors[1], fieldColors[2], fieldColors[3]])
			fee = BigNumber.from(0)
			await expect(
				buildShield(shieldManager.connect(alice), {
					field,
					hardware,
					frame,
					colors,
					fee,
					tokenId
				})
			).revertedWith('ColorError()')
		})
		it('builds shield for free for WL user', async () => {
			await accessManager.connect(owner).toggleItemWhitelist(alice.address, FREE_BUILD)

			const { shieldHash } = await buildShield(shieldManager.connect(alice), {
				field,
				hardware: MULTI_HARDWARE,
				frame,
				colors,
				fee: MULTI_HARDWARE_FEE,
				tokenId
			})

			const shield = await shieldManager.shields(tokenId)

			expect(await shieldManager.shieldHashes(shieldHash)).equal(true)
			expect(shield.hardware).deep.equal(MULTI_HARDWARE)
			expect(shield.frame).equal(frame)
		})
		it.skip('builds if shield is staked in pfpStaker', async () => {
			//  Set relevant contracts for test
			await shieldManager.connect(owner).setPfpStaker(pfpStaker.address)
			await pfpStaker.setShieldContract(shieldManager.address)
			console.log(shieldManager.address)
			console.log(await pfpStaker.enabledPfpContracts(shieldManager.address))

			// Stake shield on pfpStaker
			await pfpStaker.connect(alice).stakeNFT(alice.address, shieldManager.address, 1)
			expect(await shieldManager.ownerOf(tokenId)).equal(pfpStaker.address)

			const { shieldHash } = await buildShield(shieldManager.connect(alice), {
				field,
				hardware: MULTI_HARDWARE,
				frame,
				colors,
				fee: MULTI_HARDWARE_FEE,
				tokenId
			})

			//  Check shield has been built correctly
			const shield = await shieldManager.shields(tokenId)
			expect(await shieldManager.shieldHashes(shieldHash)).equal(true)
			expect(shield.hardware).deep.equal(MULTI_HARDWARE)
			expect(shield.frame).equal(frame)
		})
		it('builds shield for 50% off for WL user', async () => {
			await shieldManager.connect(owner).toggleItemWhitelist(alice.address, HALF_PRICE_BUILD)

			const { shieldHash } = await buildShield(shieldManager.connect(alice), {
				field,
				hardware: MULTI_HARDWARE,
				frame,
				colors,
				fee: MULTI_HARDWARE_FEE.div(2),
				tokenId
			})

			const shield = await shieldManager.shields(tokenId)

			expect(await shieldManager.shieldHashes(shieldHash)).equal(true)
			expect(shield.hardware).deep.equal(MULTI_HARDWARE)
			expect(shield.frame).equal(frame)
		})
	})

	describe('Edit Shield', () => {
		let frame: number
		let field: number
		let hardware: any[]
		let colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish]
		let fee: BigNumber
		let tokenId: number
		let firstShieldHash: string
		let shield: any

		// Before each we setup the shield manager contract + build a shield for alice
		beforeEach(async () => {
			field = BASIC_FIELD
			hardware = BASIC_HARDWARE
			frame = 0
			colors = encodeColors([fieldColors[0]])
			fee = BigNumber.from(0)
			tokenId = 1

			//await accessManager.connect(owner).setShieldManager(shieldManager.address)

			await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })

			const { shieldHash } = await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee,
				tokenId
			})
			firstShieldHash = shieldHash
		})
		it('reverts if the shieldhash is not owned by the caller', async () => {
			await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })

			await expect(
				shieldManager
					.connect(bob)
					.buildShield(field, [1, 999, 999, 999, 999, 999, 999, 999, 999], frame, colors, tokenId)
			).revertedWith('Unauthorised()')
		})
		it('reverts if the new shield is a duplicate', async () => {
			await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })

			await expect(
				shieldManager
					.connect(alice)
					.buildShield(
						BASIC_FIELD,
						[999, 999, 999, 999, 1, 999, 999, 999, 999],
						NO_FRAME,
						colors,
						tokenId
					)
			).revertedWith('DuplicateShield()')
		})
		it('edits shield and charges for new frame', async () => {
			const { shieldHash: newShieldHash } = await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame: ADORNED_FRAME,
				colors,
				fee: ADORNED_FRAME_FEE,
				tokenId
			})

			const shieldUpdate = await shieldManager.shields(tokenId)

			expect(await shieldManager.shieldHashes(firstShieldHash)).equal(false)
			expect(await shieldManager.shieldHashes(newShieldHash)).equal(true)
			expect(shieldUpdate.field).equal(field)
			expect(shieldUpdate.frame).equal(ADORNED_FRAME)
		})
		it('edits shield and charges for new frame and hardware and field', async () => {
			await shieldManager.mintShieldPass(bob.address, { value: MINT_FEE })

			const { shieldHash: newShieldHash } = await buildShield(shieldManager.connect(alice), {
				field: OLYMPIC_FIELD,
				hardware: MULTI_HARDWARE,
				frame: ADORNED_FRAME,
				colors: colorList[3],
				fee: ADORNED_FRAME_FEE.add(MULTI_HARDWARE_FEE).add(OLYMPIC_FIELD_FEE),
				tokenId
			})

			const shieldUpdate = await shieldManager.shields(tokenId)

			expect(await shieldManager.shieldHashes(firstShieldHash)).equal(false)
			expect(await shieldManager.shieldHashes(newShieldHash)).equal(true)
			expect(shieldUpdate.field).equal(OLYMPIC_FIELD)
			expect(shieldUpdate.hardware).deep.equal(MULTI_HARDWARE)
			expect(shieldUpdate.frame).equal(ADORNED_FRAME)
		})
		it('edits shield changing frame, then edits changing hardware.', async () => {
			await shieldManager.mintShieldPass(bob.address, { value: MINT_FEE })

			const { shieldHash: newShieldHash1 } = await buildShield(shieldManager.connect(alice), {
				field: OLYMPIC_FIELD,
				hardware: BASIC_HARDWARE,
				frame: ADORNED_FRAME,
				colors: colorList[3],
				fee: ADORNED_FRAME_FEE.add(OLYMPIC_FIELD_FEE),
				tokenId
			})

			const shield1 = await shieldManager.shields(tokenId)

			expect(await shieldManager.shieldHashes(firstShieldHash)).equal(false)
			expect(await shieldManager.shieldHashes(newShieldHash1)).equal(true)
			expect(shield1.hardware).deep.equal(BASIC_HARDWARE)
			expect(shield1.frame).equal(ADORNED_FRAME)

			const { shieldHash: newShieldHash2 } = await buildShield(shieldManager.connect(alice), {
				field: OLYMPIC_FIELD,
				hardware: MULTI_HARDWARE,
				frame: ADORNED_FRAME,
				colors: colorList[3],
				fee: MULTI_HARDWARE_FEE,
				tokenId
			})

			const shield2 = await shieldManager.shields(tokenId)

			expect(await shieldManager.shieldHashes(newShieldHash1)).equal(false)
			expect(await shieldManager.shieldHashes(newShieldHash2)).equal(true)
			expect(shield2.hardware).deep.equal(MULTI_HARDWARE)
			expect(shield2.frame).equal(ADORNED_FRAME)
		})
		it('edits shield and doesnt charge for downgrade', async () => {
			const { shieldHash: newShieldHash1 } = await buildShield(shieldManager.connect(alice), {
				field: OLYMPIC_FIELD,
				hardware: BASIC_HARDWARE,
				frame: ADORNED_FRAME,
				colors: colorList[3],
				fee: ADORNED_FRAME_FEE.add(OLYMPIC_FIELD_FEE),
				tokenId
			})

			const { shieldHash: newShieldHash2 } = await buildShield(shieldManager.connect(alice), {
				field: HEROIC_FIELD,
				hardware: BASIC_HARDWARE,
				frame: ADORNED_FRAME,
				colors: colorList[2],
				fee: getBigNumber(0),
				tokenId
			})

			const shield2 = await shieldManager.shields(tokenId)

			expect(await shieldManager.shieldHashes(newShieldHash1)).equal(false)
			expect(await shieldManager.shieldHashes(newShieldHash2)).equal(true)
			expect(shield2.hardware).deep.equal(BASIC_HARDWARE)
			expect(shield2.frame).equal(ADORNED_FRAME)
		})
	})

	// // ---------------------------------------------------------------------------------------------------
	// // Fees
	// // ---------------------------------------------------------------------------------------------------

	describe('fees', () => {
		let frames: number[]
		let fields: number[]
		let fieldFee: BigNumber[]
		let hardwares: number[][]
		let colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish]
		let fees: BigNumber[]
		let to: string

		beforeEach(async () => {
			fields = [BASIC_FIELD, EPIC_FIELD, HEROIC_FIELD, OLYMPIC_FIELD, LEGENDARY_FIELD]
			hardwares = [BASIC_HARDWARE, EPIC_HARDWARE, DOUBLE_HARDWARE, MULTI_HARDWARE]
			frames = [
				NO_FRAME,
				ADORNED_FRAME,
				MENACING_FRAME,
				SECURED_FRAME,
				FLORATED_FRAME,
				EVERLASTING_FRAME
			]

			// add the access level passes
			await accessManager
				.connect(owner)
				.addItem(
					getBigNumber(BASIC_ACCESS_ITEM.price),
					BASIC_ACCESS_ITEM.maxSupply,
					BASIC_ACCESS_ITEM.accessLevel,
					BASIC_ACCESS_ITEM.resaleRoyalty
				)

			await accessManager
				.connect(owner)
				.addItem(
					getBigNumber(BRONZE_ACCESS_ITEM.price),
					BRONZE_ACCESS_ITEM.maxSupply,
					BRONZE_ACCESS_ITEM.accessLevel,
					BRONZE_ACCESS_ITEM.resaleRoyalty
				)

			await accessManager
				.connect(owner)
				.addItem(
					getBigNumber(SILVER_ACCESS_ITEM.price),
					SILVER_ACCESS_ITEM.maxSupply,
					SILVER_ACCESS_ITEM.accessLevel,
					SILVER_ACCESS_ITEM.resaleRoyalty
				)
			await accessManager
				.connect(owner)
				.addItem(
					getBigNumber(GOLD_ACCESS_ITEM.price),
					GOLD_ACCESS_ITEM.maxSupply,
					GOLD_ACCESS_ITEM.accessLevel,
					GOLD_ACCESS_ITEM.resaleRoyalty
				)

			await accessManager.setItemMintLive(BASIC_ACCESS, true)
			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
			await accessManager.setItemMintLive(SILVER_ACCESS, true)
			await accessManager.setItemMintLive(GOLD_ACCESS, true)

			await shieldManager.connect(owner).setPublicMintActive(true)

			const tx = await (
				await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			).wait()
			tokenId = parseInt(tx.events?.[0].args?.tokenId)
			console.log('tokenId', tokenId)
		})
		// it would be nice to bundle the below tests into one, but it involved resetting the hardhat state and that really slowed things down
		it('returns the correct values for each field category at basic level', async () => {
			await accessManager.mintItem(BASIC_ACCESS, alice.address, {
				value: getBigNumber(BASIC_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < fields.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[j],
					hardware: hardwares[0],
					frame: frames[0],
					colors: colorList[j],
					fee: expectedFieldFeesBasic[j],
					tokenId
				})

				//	console.log(await shieldManager.tokenURI(tokenId))

				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid

				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFieldFeesBasic[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each field category at bronze level', async () => {
			await accessManager.mintItem(BRONZE_ACCESS, alice.address, {
				value: getBigNumber(BRONZE_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < fields.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[j],
					hardware: hardwares[0],
					frame: frames[0],
					colors: colorList[j],
					fee: expectedFieldFeesBronze[j],
					tokenId
				})

				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).field).equal(fields[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFieldFeesBronze[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each field category at silver level', async () => {
			await accessManager.mintItem(SILVER_ACCESS, alice.address, {
				value: getBigNumber(SILVER_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < fields.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[j],
					hardware: hardwares[0],
					frame: frames[0],
					colors: colorList[j],
					fee: expectedFieldFeesSilver[j],
					tokenId
				})

				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).field).equal(fields[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFieldFeesSilver[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each field category at gold level', async () => {
			await accessManager.mintItem(GOLD_ACCESS, alice.address, {
				value: getBigNumber(GOLD_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < fields.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[j],
					hardware: hardwares[0],
					frame: frames[0],
					colors: colorList[j],
					fee: expectedFieldFeesGold[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).field).equal(fields[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFieldFeesGold[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each hardware category at basic level', async () => {
			await accessManager.mintItem(BASIC_ACCESS, alice.address, {
				value: getBigNumber(BASIC_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each hardware type
			for (let j = 0; j < hardwares.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)
				console.log(tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[j],
					frame: frames[0],
					colors: colorList[0],
					fee: expectedHardwareFeesBasic[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				//console.log(await shieldManager.tokenURI(tokenId))

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).hardware).deep.equal(hardwares[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedHardwareFeesBasic[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each hardware category at bronze level', async () => {
			await accessManager.mintItem(BRONZE_ACCESS, alice.address, {
				value: getBigNumber(BRONZE_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each hardware type
			for (let j = 0; j < hardwares.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[j],
					frame: frames[0],
					colors: colorList[0],
					fee: expectedHardwareFeesBronze[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).hardware).deep.equal(hardwares[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedHardwareFeesBronze[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each hardware category at silver level', async () => {
			await accessManager.mintItem(SILVER_ACCESS, alice.address, {
				value: getBigNumber(SILVER_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each hardware type
			for (let j = 0; j < hardwares.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[j],
					frame: frames[0],
					colors: colorList[0],
					fee: expectedHardwareFeesSilver[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).hardware).deep.equal(hardwares[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedHardwareFeesSilver[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each hardware category at gold level', async () => {
			await accessManager.mintItem(GOLD_ACCESS, alice.address, {
				value: getBigNumber(GOLD_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each hardware type
			for (let j = 0; j < hardwares.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[j],
					frame: frames[0],
					colors: colorList[0],
					fee: expectedHardwareFeesGold[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).hardware).deep.equal(hardwares[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedHardwareFeesGold[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each frame category at basic level', async () => {
			await accessManager.mintItem(BASIC_ACCESS, alice.address, {
				value: getBigNumber(BASIC_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < frames.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[0],
					frame: frames[j],
					colors: colorList[0],
					fee: expectedFrameFeesBasic[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).frame).equal(frames[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFrameFeesBasic[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each frame at bronze level', async () => {
			await accessManager.mintItem(BRONZE_ACCESS, alice.address, {
				value: getBigNumber(BRONZE_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < hardwares.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[0],
					frame: frames[j],
					colors: colorList[0],
					fee: expectedFrameFeesBronze[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).frame).equal(frames[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFrameFeesBronze[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each frame at silver level', async () => {
			await accessManager.mintItem(SILVER_ACCESS, alice.address, {
				value: getBigNumber(SILVER_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < hardwares.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[0],
					frame: frames[j],
					colors: colorList[0],
					fee: expectedFrameFeesSilver[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).frame).equal(frames[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFrameFeesSilver[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('returns the correct values for each frame at gold level', async () => {
			await accessManager.mintItem(GOLD_ACCESS, alice.address, {
				value: getBigNumber(GOLD_ACCESS_ITEM.price)
			})

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			let shieldManagerWorkingBalance = shieldManagerBalancePrevious

			// for each field type
			for (let j = 0; j < hardwares.length; j++) {
				const tx = await (
					await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
				).wait()
				tokenId = parseInt(tx.events?.[0].args?.tokenId)

				const shieldHash = await buildShield(shieldManager.connect(alice), {
					field: fields[0],
					hardware: hardwares[0],
					frame: frames[j],
					colors: colorList[0],
					fee: expectedFrameFeesGold[j],
					tokenId
				})
				const currentBalance = await hardhatEthers.provider.getBalance(shieldManager.address)

				// check shield was built correctly and the correct fee was paid
				expect((await shieldManager.shields(tokenId)).frame).equal(frames[j])
				expect(currentBalance.sub(shieldManagerWorkingBalance)).equal(
					expectedFrameFeesGold[j].add(MINT_FEE)
				)

				shieldManagerWorkingBalance = currentBalance
			}
		})
		it('charges the correct fee for many paid types', async () => {
			colors = encodeColors([fieldColors[0], fieldColors[1]])
			console.log(colors)

			const fee = OLYMPIC_FIELD_FEE.add(MULTI_HARDWARE_FEE).add(EVERLASTING_FRAME_FEE)

			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)

			const shieldHash = await buildShield(shieldManager.connect(alice), {
				field: OLYMPIC_FIELD,
				hardware: MULTI_HARDWARE,
				frame: EVERLASTING_FRAME,
				colors: colors,
				fee,
				tokenId
			})
			const shieldManagerBalanceUpdated = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)

			expect(shieldManagerBalanceUpdated.sub(shieldManagerBalancePrevious)).equal(fee)
			expect((await shieldManager.shields(tokenId)).frame).equal(EVERLASTING_FRAME)
		})
		it('withdraws funds from shield manager to owner', async () => {
			const shieldManagerBalancePrevious = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)
			const ownerBalancePrevious = await hardhatEthers.provider.getBalance(owner.address)

			await buildShield(shieldManager.connect(alice), {
				field: OLYMPIC_FIELD,
				hardware: BASIC_HARDWARE,
				frame: NO_FRAME,
				colors: encodeColors([fieldColors[0], fieldColors[1]]),
				fee: OLYMPIC_FIELD_FEE,
				tokenId
			})
			const shieldManagerBalanceUpdated = await hardhatEthers.provider.getBalance(
				shieldManager.address
			)

			expect(shieldManagerBalanceUpdated.sub(shieldManagerBalancePrevious)).equal(OLYMPIC_FIELD_FEE)

			await shieldManager.collectFees()

			const ownerBalanceUpdated = await hardhatEthers.provider.getBalance(owner.address)
			expect(ownerBalanceUpdated.sub(ownerBalancePrevious)).equal(OLYMPIC_FIELD_FEE)
			expect(await hardhatEthers.provider.getBalance(shieldManager.address)).equal(0)
			expect((await shieldManager.shields(tokenId)).field).equal(OLYMPIC_FIELD)
		})
	})

	// ---------------------------------------------------------------------------------------------------
	// TokenURI
	// ---------------------------------------------------------------------------------------------------

	describe('tokenURI', () => {
		let field: number
		let frame: number
		let hardware: number[]
		let colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish]
		let fee: BigNumber
		let tokenId: BigNumberish

		beforeEach(async () => {
			field = EPIC_FIELD
			hardware = BASIC_HARDWARE
			frame = ADORNED_FRAME
			colors = encodeColors([fieldColors[0], fieldColors[1], 0, 0])
			fee = ADORNED_FRAME_FEE.add(EPIC_FIELD_FEE)

			await shieldManager.connect(owner).setPublicMintActive(true)

			const tx = await (
				await shieldManager.mintShieldPass(alice.address, { value: MINT_FEE })
			).wait()
			tokenId = parseInt(tx.events?.[0].args?.tokenId)
			console.log('tokenId', tokenId)
		})

		it('returns proper JSON', async () => {
			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee,
				tokenId
			})

			const content = extractJSONFromURI(await shieldManager.tokenURI(tokenId))
			expect(content).haveOwnProperty('name').is.a('string')
			expect(content).haveOwnProperty('description').is.a('string')
			expect(content).haveOwnProperty('image').is.a('string')
			expect(content).haveOwnProperty('attributes').is.a('array')
			expect(content.attributes[0]).haveOwnProperty('trait_type').equal('Field')
			expect(content.attributes[1]).haveOwnProperty('trait_type').equal('Hardware')
			expect(content.attributes[2]).haveOwnProperty('trait_type').equal('Status')
			expect(content.attributes[3]).haveOwnProperty('trait_type').equal('Field Type')
			expect(content.attributes[4]).haveOwnProperty('trait_type').equal('Hardware Type')
			expect(content.attributes[5]).haveOwnProperty('trait_type').equal('Frame')
			expect(content.attributes[6]).haveOwnProperty('trait_type').equal('Color 1')
		})

		it('returns the correct tokenURI', async () => {
			await buildShield(shieldManager.connect(alice), {
				field,
				hardware: MULTI_HARDWARE,
				frame,
				colors,
				fee: EPIC_FIELD_FEE.add(MULTI_HARDWARE_FEE).add(ADORNED_FRAME_FEE),
				tokenId
			})

			const tokenURI = await shieldManager.tokenURI(tokenId)

			expect(tokenURI).toMatchSnapshot()
		})

		it('returns the correct blazon with a frame', async () => {
			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee,
				tokenId
			})

			const content = extractJSONFromURI(await shieldManager.tokenURI(tokenId))
			expect(content.name).equal('Adorned: Shovel on Navy Blue and Cobalt Bordure Rayonny')
		})

		it('returns the correct blazon without a frame', async () => {
			frame = 0
			fee = EPIC_FIELD_FEE

			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee,
				tokenId
			})

			const content = extractJSONFromURI(await shieldManager.tokenURI(tokenId))
			expect(content.name).equal('Shovel on Navy Blue and Cobalt Bordure Rayonny')
		})

		// eslint-disable-next-line jest/expect-expect
		it('gas min SVG lookup', async () => {
			field = EPIC_FIELD
			hardware = BASIC_HARDWARE
			frame = 0
			fee = EPIC_FIELD_FEE
			colors = encodeColors([fieldColors[0], fieldColors[1]])

			const shieldManagerGasTestFactory = await hardhatEthers.getContractFactory('ShieldsGasTest')
			const shieldManagerGasTest = (await shieldManagerGasTestFactory.deploy(
				shieldManager.address
			)) as ShieldsGasTest

			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors: encodeColors([fieldColors[0], fieldColors[1]]),
				fee,
				tokenId
			})

			await snapshotGasCost(await shieldManagerGasTest.gasSnapshotTokenURI(tokenId))
		})

		// test this with a max SVG test setup
		// eslint-disable-next-line jest/expect-expect
		it('gas max SVG lookup', async () => {
			field = EPIC_FIELD
			hardware = BASIC_HARDWARE
			colors = encodeColors([fieldColors[0], fieldColors[1]])
			fee = EPIC_FIELD_FEE.add(ADORNED_FRAME_FEE)

			const shieldManagerGasTestFactory = await hardhatEthers.getContractFactory('ShieldsGasTest')
			const shieldManagerGasTest = (await shieldManagerGasTestFactory.deploy(
				shieldManager.address
			)) as ShieldsGasTest

			await buildShield(shieldManager.connect(alice), {
				field,
				hardware,
				frame,
				colors,
				fee,
				tokenId
			})

			await snapshotGasCost(await shieldManagerGasTest.gasSnapshotTokenURI(tokenId))
		})
	})
})
