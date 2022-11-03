import { getBigNumber } from '../utils/helpers'
import { takerOrderTypes } from '../utils/order-helper'
import { processProposal } from '../utils/processProposal'
import { voteProposal } from '../utils/voteProposal'

import { COMMISSION_BASED_FUNCTIONS, COMMISSION_FREE_FUNCTIONS } from '../../config'
import {
	AccessManager,
	ExecutionManager,
	ForumFactory,
	ForumGroup,
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
	let forum: ForumGroup
	let executionManager: ExecutionManager
	let joepegsHandler: JoepegsProposalHandler

	beforeEach(async function () {
		;[owner, wallet, alice, bob, testAddress1, testAddress2] = await hardhatEthers.getSigners()

		await deployments.fixture(['Forum', 'Shields'])
		forum = await hardhatEthers.getContract('ForumGroup')
		executionManager = await hardhatEthers.getContract('ExecutionManager')
		joepegsHandler = await hardhatEthers.getContract('JoepegsProposalHandler')
		shieldManager = await hardhatEthers.getContract('ShieldManager')
	})

	describe('general execution manager functions', function () {
		it('should revert if non owner attempts to add a proposalHandler, or unset restrcted mode', async function () {
			await expect(
				executionManager.connect(bob).addProposalHandler(testAddress1.address, testAddress2.address)
			).revertedWith('UNAUTHORIZED')

			await expect(executionManager.connect(bob).setRestrictedExecution(0)).revertedWith(
				'UNAUTHORIZED'
			)
		})
		it('should allow owner to add a proposalHandler, then unset restrcted mode', async function () {
			await executionManager.addProposalHandler(testAddress1.address, testAddress2.address)
			expect(await executionManager.proposalHandlers(testAddress1.address)).equal(
				testAddress2.address
			)

			await executionManager.setRestrictedExecution(0)
			expect(await executionManager.restrictedExecution()).equal(0)
		})
		it('should revert if restricedExecution enabled and unknown contract called', async function () {
			//reset restricted mode from last test
			await executionManager.setRestrictedExecution(1)

			await expect(executionManager.manageExecution(testAddress2.address, 1, '0x00')).revertedWith(
				'UnapprovedContract()'
			)
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
				[sender.address, receiver.address],
				[ZERO_ADDRESS, executionManager.address, ZERO_ADDRESS],
				[30, 0, 50, 60]
			)

			// Send some avax to the address to cover commission payment
			const tx = {
				to: forum.address,
				value: hardhatEthers.utils.parseEther('2')
			}
			await sender.sendTransaction(tx)

			// Create a taker order
			const payload = hardhatEthers.utils.defaultAbiCoder.encode(takerOrderTypes, [
				false,
				sender.address,
				getBigNumber(1),
				getBigNumber(1),
				getBigNumber(9000),
				'0x00'
			])

			const payloadWithNoCommissionFunctionSelector =
				COMMISSION_FREE_FUNCTIONS[0] + payload.substring(2)
			console.log({
				a: await joepegsHandler.commissionBasedFunctions(COMMISSION_BASED_FUNCTIONS[0])
			})
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
