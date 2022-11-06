import deployFrameGenerator from '../../utils/deployFrameGenerator'
import deployTestFieldGenerator from '../../utils/deployTestFieldGenerator'
import deployTestHardwareGenerator from '../../utils/deployTestHardwareGenerator'

import {
	AccessManager,
	EmblemWeaver,
	ExecutionManager,
	FieldGenerator,
	ForumFactoryV2,
	ForumGroupV2,
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

let forumContract: ForumGroupV2
let forumFactory: ForumFactoryV2
let forumStandaloneGas: string
let tableProxyGas: string

const getGas = async (tx: ContractTransaction) => {
	const receipt = await hardhatEthers.provider.getTransactionReceipt(tx.hash)
	return receipt.gasUsed.toString()
}

describe.only('Forum Factory', function () {
	let owner: SignerWithAddress
	let wallet: SignerWithAddress
	let alice: SignerWithAddress
	let bob: SignerWithAddress
	let relay: SignerWithAddress

	beforeEach(async function () {
		;[owner, wallet, alice, bob, relay] = await hardhatEthers.getSigners()

		// Deploy master ForumGroupV2
		forumContract = (await (
			await hardhatEthers.getContractFactory('ForumGroup_v2')
		).deploy()) as ForumGroupV2

		// Deploy the Forum Factory
		// We can use ZERO_ADDRESS for execution manager in these tests since we don't test any transaction executions here
		forumFactory = (await (
			await hardhatEthers.getContractFactory('ForumFactoryV2')
		).deploy(owner.address, forumContract.address, ZERO_ADDRESS)) as ForumFactoryV2
	})

	it('Should deploy master forumContract', async function () {
		forumContract = (await (
			await hardhatEthers.getContractFactory('ForumGroup_v2')
		).deploy()) as ForumGroupV2
		forumStandaloneGas = await getGas(forumContract.deployTransaction)
		expect(forumContract.address).not.equal(0x0)
	})
	// We can use ZERO_ADDRESS for execution manager in these tests since we don't test any transaction executions here
	it('Should deploy forumFactory contract', async function () {
		await (
			await hardhatEthers.getContractFactory('ForumFactoryV2')
		).deploy(owner.address, forumContract.address, ZERO_ADDRESS)
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
					[30, 12, 50, 60],
					{ value: 0 }
				)
		).wait()

		tableProxyGas = tx.gasUsed.toString()

		// ! need to check for success
	})
	it('Should revert if over 100 members added', async function () {
		await forumFactory.setLaunched(true)

		await expect(
			forumFactory
				.connect(wallet)
				.deployGroup('testTable', 'T', beyondMemberLimit101, [30, 0, 50, 60], { value: 0 })
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
				[30, 12, 50, 60],
				{ value: 0 }
			)

		expect(Number(forumStandaloneGas)).greaterThan(Number(tableProxyGas) * 10)
	})
})

const beyondMemberLimit101 = [
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
	'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
	'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
	'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
	'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
	'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D',
	'0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'
]
