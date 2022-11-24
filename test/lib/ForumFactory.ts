import { CommissionManager, ForumFactory, ForumGroup } from '../../typechain'
import { ZERO_ADDRESS } from '../config'

import { ContractTransaction } from '@ethersproject/contracts'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { ethers as hardhatEthers, deployments } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

let forumContract: ForumGroup
let forumFactory: ForumFactory
let commissionManager: CommissionManager
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

	beforeEach(async function () {
		;[owner, wallet, alice, bob, relay] = await hardhatEthers.getSigners()

		// Similar to deploying the master forum multisig
		await deployments.fixture(['Forum'])
		forumContract = await hardhatEthers.getContract('ForumGroup')
		forumFactory = await hardhatEthers.getContract('ForumFactory')
		commissionManager = await hardhatEthers.getContract('CommissionManager')

		// Set commission manager and master forum
		await forumFactory.setCommissionManager(commissionManager.address)
		await forumFactory.setForumMaster(forumContract.address)
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
		await (await hardhatEthers.getContractFactory('ForumFactory')).deploy(owner.address)
		expect(forumFactory.address).not.equal(0x0)
	})
	// eslint-disable-next-line jest/expect-expect
	it('Should deploy forum via forumFactory contract', async function () {
		const tx = await (
			await forumFactory
				.connect(wallet)
				.deployGroup(
					'testTable',
					'T',
					['0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'],
					[30, 12, 50, 60],
					[],
					{ value: 0 }
				)
		).wait()

		tableProxyGas = tx.gasUsed.toString()

		// ! need to check for success
	})
	it('Should revert if over 100 members added', async function () {
		await expect(
			forumFactory
				.connect(wallet)
				.deployGroup('testTable', 'T', beyondMemberLimit101, [60, 100, 50, 60], [], {
					value: 0
				})
		).revertedWith('MemberLimitExceeded()')
	})
	it('Minimal Proxy deployment should cost 10x less than a standard deployment', async function () {
		await forumFactory
			.connect(wallet)
			.deployGroup(
				'testTable',
				'T',
				['0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'],
				[30, 12, 50, 60],
				[],
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
