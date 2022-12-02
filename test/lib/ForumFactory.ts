import {
	CommissionManager,
	ForumFactory,
	ForumGroup,
	ForumGroupFundraise,
	ForumWithdrawal,
	PfpStaker
} from '../../typechain'
import { ZERO_ADDRESS } from '../config'

import { ContractTransaction } from '@ethersproject/contracts'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { ethers as hardhatEthers, deployments } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

let forumContract: ForumGroup
let forumFactory: ForumFactory
let commissionManager: CommissionManager
let withdrawalExt: ForumWithdrawal
let fundraiseExt: ForumGroupFundraise
let pfpStaker: PfpStaker
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
	let forumGroup: ForumGroup

	beforeEach(async function () {
		;[owner, wallet, alice, bob, relay] = await hardhatEthers.getSigners()

		// Similar to deploying the master forum multisig
		await deployments.fixture(['Forum'])
		forumContract = await hardhatEthers.getContract('ForumGroup')
		forumFactory = await hardhatEthers.getContract('ForumFactory')
		commissionManager = await hardhatEthers.getContract('CommissionManager')
		withdrawalExt = await hardhatEthers.getContract('ForumWithdrawal')
		fundraiseExt = await hardhatEthers.getContract('ForumGroupFundraise')
		pfpStaker = await hardhatEthers.getContract('PfpStaker')

		// Set commission manager and master forum
		await forumFactory.setCommissionManager(commissionManager.address)
		await forumFactory.setForumMaster(forumContract.address)
		await forumFactory.setWithdrawalExtension(withdrawalExt.address) // exact address does not matter for these tests
		await forumFactory.setFundraiseExtension(fundraiseExt.address)
		await forumFactory.setPfpStaker(pfpStaker.address)
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
	it('Should deploy forum via forumFactory contract and check gas', async function () {
		const tx = await (
			await forumFactory
				.connect(wallet)
				.deployGroup(
					'testTable',
					'T',
					[30, 12, 50, 60],
					['0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'],
					[],
					{ value: 0 }
				)
		).wait()

		tableProxyGas = tx.gasUsed.toString()

		const groupAddress = `0x${tx.logs[1].topics[1].substring(26)}`
		forumGroup = await hardhatEthers.getContractAt('ForumGroup', groupAddress)

		// Correct name and extensions set
		expect(await forumGroup.name()).to.equal('testTable')
		expect(await forumGroup.extensions(withdrawalExt.address)).to.equal(true)
		expect(await forumGroup.extensions(fundraiseExt.address)).to.equal(true)
	})
	it('Should revert if over 100 members added', async function () {
		await expect(
			forumFactory
				.connect(wallet)
				.deployGroup('testTable', 'T', [60, 100, 50, 60], beyondMemberLimit101, [], {
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
				[30, 12, 50, 60],
				['0xfF626F22D92506b74eeC6ccb15412E5a9D6A592D'],
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
