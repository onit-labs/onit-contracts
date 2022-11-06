import deployFrameGenerator from '../../utils/deployFrameGenerator'
import deployTestFieldGenerator from '../../utils/deployTestFieldGenerator'
import deployTestHardwareGenerator from '../../utils/deployTestHardwareGenerator'

import {
	AccessManager,
	EmblemWeaver,
	ExecutionManager,
	FieldGenerator,
	ForumFactory,
	ForumGroup,
	FrameGenerator,
	PfpStaker,
	ShieldManager,
	TestFieldGenerator,
	TestHardwareGenerator
} from '../../../typechain'
import { ZERO_ADDRESS } from '../../config'

import { ContractTransaction } from '@ethersproject/contracts'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

let forumContract: ForumGroup
let forumFactory: ForumFactory
let forumStandaloneGas: string
let tableProxyGas: string

const getGas = async (tx: ContractTransaction) => {
	const receipt = await hardhatEthers.provider.getTransactionReceipt(tx.hash)
	return receipt.gasUsed.toString()
}

describe('Forum Factory', function () {
	let owner: SignerWithAddress
	let wallet: SignerWithAddress
	let alice: SignerWithAddress
	let bob: SignerWithAddress
	let relay: SignerWithAddress
	let emblemWeaver: EmblemWeaver
	let frameGenerator: FrameGenerator
	let fieldGenerator: FieldGenerator
	let hardwareGenerator: TestHardwareGenerator
	// let hardwareGenerator: HardwareGenerator
	let shieldManager: ShieldManager
	let accessManager: AccessManager
	let pfpStaker: PfpStaker

	beforeEach(async function () {
		;[owner, wallet, alice, bob, relay] = await hardhatEthers.getSigners()

		// The below production of shieldManager and emblemWeaver should be raplaced by the above when the deployments are corrected to take the SVGs on hardhat
		////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////

		// Deploy Generators
		frameGenerator = (await deployFrameGenerator()) as FrameGenerator
		hardwareGenerator = (await deployTestHardwareGenerator()) as TestHardwareGenerator
		fieldGenerator = (await deployTestFieldGenerator()) as TestFieldGenerator

		// Deploy EmblemWeaver
		emblemWeaver = (await (
			await hardhatEthers.getContractFactory('EmblemWeaver')
		).deploy(
			fieldGenerator.address,
			hardwareGenerator.address,
			frameGenerator.address
		)) as EmblemWeaver

		// Deploy ShieldManager
		shieldManager = (await (
			await hardhatEthers.getContractFactory('ShieldManager')
		).deploy(owner.address, 'Shields', 'SHIELDS', emblemWeaver.address)) as ShieldManager

		// Deploy master ForumGroup
		forumContract = (await (
			await hardhatEthers.getContractFactory('ForumGroup')
		).deploy()) as ForumGroup

		// Deploy the Forum Factory
		// We can use ZERO_ADDRESS for execution manager in these tests since we don't test any transaction executions here
		forumFactory = (await (
			await hardhatEthers.getContractFactory('ForumFactory')
		).deploy(
			owner.address,
			forumContract.address,
			ZERO_ADDRESS,
			shieldManager.address
		)) as ForumFactory
		////////////////////////////////////////////////////////////////
		////////////////////////////////////////////////////////////////

		// Deploy the pfpStaker
		pfpStaker = (await (
			await hardhatEthers.getContractFactory('PfpStaker')
		).deploy(owner.address, shieldManager.address, forumFactory.address)) as PfpStaker

		// set relay and pfp staker address in factory
		await forumFactory.connect(owner).setForumRelay(relay.address)
		await forumFactory.connect(owner).setPfpStaker(pfpStaker.address)

		// set forumFactory and set mint active in shieldManager - legacy roundtable naming
		await shieldManager.connect(owner).setPublicMintActive(true)
		await shieldManager.connect(owner).setRoundtableFactory(forumFactory.address)
	})

	it('Should deploy master forumContract', async function () {
		forumContract = (await (
			await hardhatEthers.getContractFactory('ForumGroup')
		).deploy()) as ForumGroup
		forumStandaloneGas = await getGas(forumContract.deployTransaction)
		expect(forumContract.address).not.equal(0x0)
	})
	// We can use ZERO_ADDRESS for execution manager in these tests since we don't test any transaction executions here
	it('Should deploy forumFactory contract', async function () {
		await (
			await hardhatEthers.getContractFactory('ForumFactory')
		).deploy(owner.address, forumContract.address, ZERO_ADDRESS, shieldManager.address)
		expect(forumFactory.address).not.equal(0x0)
	})
	// eslint-disable-next-line jest/expect-expect
	it('Should deploy forum via forumFactory contract', async function () {
		await forumFactory.setLaunched(true)

		const tx = await (
			await forumFactory
				.connect(wallet)
				.deployGroup(
					'testTable',
					'T',
					['0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'],
					[30, 0, 50, 60],
					{ value: 0 }
				)
		).wait()

		tableProxyGas = tx.gasUsed.toString()

		//const multisigAddress = `0x${tx.events?.[3].topics[1].slice(-40)}`
		//const rt = await hardhatEthers.getContractAt('ForumGroup', multisigAddress)
		//console.log(await rt.uri(0))

		// pfpStaker will hold the shield of the group
		expect(await shieldManager.balanceOf(pfpStaker.address)).equal(1)
		expect(await shieldManager.ownerOf(1)).equal(pfpStaker.address)
	})
	it('Should revert if over 12 members added', async function () {
		await forumFactory.setLaunched(true)

		await expect(
			forumFactory
				.connect(wallet)
				.deployGroup(
					'testTable',
					'T',
					[
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
						'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'
					],
					[30, 0, 50, 60],
					{ value: 0 }
				)
		).revertedWith('MemberLimitExceeded()')
	})
	it('Minimal Proxy deployment should cost 10x less than a standard deployment', async function () {
		await forumFactory.setLaunched(true)

		await forumFactory
			.connect(wallet)
			.deployGroup(
				'testTable',
				'T',
				['0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'],
				[30, 0, 50, 60],
				{ value: 0 }
			)

		expect(Number(forumStandaloneGas)).greaterThan(Number(tableProxyGas) * 10)
	})
})
