import { getBigNumber } from '../utils/helpers'
import { takerOrderTypes } from '../utils/order-helper'
import { processProposal } from '../utils/processProposal'
import { voteProposal } from '../utils/voteProposal'

import { COMMISSION_BASED_FUNCTIONS, COMMISSION_FREE_FUNCTIONS } from '../../config'
import {
	AccessManager,
	ExecutionManager,
	ForumFactory,
	ForumGroupV2,
	JoepegsProposalHandler,
	PfpStaker,
	ShieldManager
} from '../../typechain'
import { CALL, ZERO_ADDRESS } from '../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

describe('Extension Manager', function () {
	let owner: SignerWithAddress
	let wallet: SignerWithAddress
	let alice: SignerWithAddress
	let bob: SignerWithAddress
	let testAddress1: SignerWithAddress
	let testAddress2: SignerWithAddress
	let shieldManager: ShieldManager
	let accessManager: AccessManager
	let pfpStaker: PfpStaker
	let forum: ForumGroupV2
	let executionManager: ExecutionManager
	let joepegsHandler: JoepegsProposalHandler

	beforeEach(async function () {
		;[owner, wallet, alice, bob, testAddress1, testAddress2] = await hardhatEthers.getSigners()

		await deployments.fixture(['Forum', 'Shields'])
		forum = await hardhatEthers.getContract('ForumGroupV2')
		executionManager = await hardhatEthers.getContract('ExecutionManager')
		joepegsHandler = await hardhatEthers.getContract('JoepegsProposalHandler')
		shieldManager = await hardhatEthers.getContract('ShieldManager')
	})

	describe('general execution manager functions', function () {
		it('should revert if non owner attempts to add a proposalHandler, or unset baseCommission', async function () {
			await expect(
				executionManager.connect(bob).addProposalHandler(testAddress1.address, testAddress2.address)
			).revertedWith('UNAUTHORIZED')

			await expect(executionManager.connect(bob).setBaseCommission(0)).revertedWith('UNAUTHORIZED')
		})
		it('should allow owner to add a proposalHandler, then unset baseCommission', async function () {
			await executionManager.addProposalHandler(testAddress1.address, testAddress2.address)
			expect(await executionManager.proposalHandlers(testAddress1.address)).equal(
				testAddress2.address
			)

			await executionManager.setBaseCommission(0)
			expect(await executionManager.baseCommission()).equal(0)
		})
		it('should take base commission if set, and not if unset', async function () {
			//reset restricted mode from last test, expect commission to be >0
			await executionManager.setBaseCommission(1)
			console.log(await executionManager.manageExecution(testAddress2.address, 1, '0x00'))

			expect(await executionManager.manageExecution(testAddress2.address, 1, '0x00')).gt(0)

			//unset restricted mode, expect 0 commission
			await executionManager.setBaseCommission(0)
			expect(await executionManager.manageExecution(testAddress2.address, 1, '0x00')).eq(0)
		})
	})
	describe('joepegs handler', function () {
		it('Should decode payload and take correct fee (free and paid) for CALL to joepegs', async () => {
			let sender: SignerWithAddress, receiver: SignerWithAddress, extension, forumAddress
			;[sender, receiver, extension] = await hardhatEthers.getSigners()

			// Deploy mock joepegs
			const JoepegsMarket = await hardhatEthers.getContractFactory('MockJoepegsExchange')
			const joepegsMarket = await JoepegsMarket.deploy()

			// Deploy execution manager which will format proposals to specific contracts to extract commission
			const ExecutionManager = await hardhatEthers.getContractFactory('ExecutionManager')
			const executionManager = await ExecutionManager.deploy(sender.address)

			// Set the handler in the execution manager
			await executionManager.addProposalHandler(joepegsMarket.address, joepegsHandler.address)

			await forum.init(
				'FORUM',
				'FORUM',
				[sender.address],
				[ZERO_ADDRESS, executionManager.address, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			// Send some avax to the address to cover commission payment
			const tx = {
				to: forum.address,
				value: hardhatEthers.utils.parseEther('2')
			}
			await sender.sendTransaction(tx)

			// Create a taker order
			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
				[
					'(bool,address,uint256,uint256,uint256,bytes)',
					'(bool,address,address,uint256,uint256,uint256,address,address,uint256,uint256,uint256,uint256,bytes,uint8,bytes32,bytes32)'
				],
				[testTakerOrder, testMakerOrder]
			)

			const payloadWithNoCommissionFunctionSelector =
				COMMISSION_FREE_FUNCTIONS[0] + payload.substring(2)
			console.log({ payloadWithNoCommissionFunctionSelector })

			expect(await hardhatEthers.provider.getBalance(executionManager.address)).equal(0)
			// Propose + process the taker order
			await processProposal(forum, [sender], 1, {
				type: CALL,
				accounts: [joepegsMarket.address],
				amounts: [getBigNumber(0)],
				payloads: [payloadWithNoCommissionFunctionSelector]
			})

			expect(await hardhatEthers.provider.getBalance(executionManager.address)).equal(0)

			const payloadWithCommissionFunctionSelector =
				COMMISSION_BASED_FUNCTIONS[0] + payload.substring(2)
			console.log({ payloadWithCommissionFunctionSelector })

			// Propose + process the taker order
			await processProposal(forum, [sender], 2, {
				type: CALL,
				accounts: [joepegsMarket.address],
				amounts: [getBigNumber(0)],
				payloads: [payloadWithCommissionFunctionSelector]
			})

			expect(await hardhatEthers.provider.getBalance(executionManager.address)).equal(
				getBigNumber(0.02)
			)
		})
	})
})

const testTakerOrder = [
	false,
	ZERO_ADDRESS,
	getBigNumber(1),
	getBigNumber(1),
	getBigNumber(9000),
	'0x00'
]

const testMakerOrder = [
	false,
	ZERO_ADDRESS,
	ZERO_ADDRESS,
	getBigNumber(1),
	getBigNumber(1),
	getBigNumber(1),
	ZERO_ADDRESS,
	ZERO_ADDRESS,
	getBigNumber(1),
	getBigNumber(1),
	getBigNumber(1),
	getBigNumber(1),
	'0x0000000000000000000000000000000000000000000000000000000000000000',
	27,
	'0x0000000000000000000000000000000000000000000000000000000000000000',
	'0x0000000000000000000000000000000000000000000000000000000000000000'
]
