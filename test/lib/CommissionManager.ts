import { getBigNumber } from '../utils/helpers'
import { takerOrderTypes } from '../utils/order-helper'
import { processProposal } from '../utils/processProposal'
import { voteProposal } from '../utils/voteProposal'

import { COMMISSION_BASED_FUNCTIONS, COMMISSION_FREE_FUNCTIONS } from '../../config'
import {
	CommissionManager,
	ForumFactory,
	ForumGroup,
	JoepegsProposalHandler,
	MockJoepegsExchange,
	PfpStaker,
	ERC721Test
} from '../../typechain'
import { CALL, ZERO_ADDRESS } from '../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

describe('Commission Manager', function () {
	let owner: SignerWithAddress
	let wallet: SignerWithAddress
	let alice: SignerWithAddress
	let bob: SignerWithAddress
	let testAddress1: SignerWithAddress
	let testAddress2: SignerWithAddress
	let forum: ForumGroup
	let executionManager: CommissionManager
	let joepegsHandler: JoepegsProposalHandler
	let joepegsMarket: MockJoepegsExchange
	let test721: ERC721Test // ERC721Test contract instance

	beforeEach(async function () {
		;[owner, wallet, alice, bob, testAddress1, testAddress2] = await hardhatEthers.getSigners()

		await deployments.fixture(['Forum', 'Shields'])
		forum = await hardhatEthers.getContract('ForumGroup')
		executionManager = await hardhatEthers.getContract('CommissionManager')
		joepegsHandler = await hardhatEthers.getContract('JoepegsProposalHandler')

		// Test erc721, deploy a test 721 contract and mint a token for founder
		test721 = (await (
			await hardhatEthers.getContractFactory('ERC721Test')
		).deploy('test', 'test')) as ERC721Test
	})

	describe('general execution manager functions', function () {
		it('should revert if non owner attempts to add a proposalHandler, or unset baseCommission', async function () {
			await expect(
				executionManager
					.connect(bob)
					.addProposalHandler(testAddress1.address, testAddress2.address)
			).revertedWith('UNAUTHORIZED')
		})
		it('should allow owner to add a proposalHandler', async function () {
			await executionManager.addProposalHandler(testAddress1.address, testAddress2.address)
			expect(await executionManager.proposalHandlers(testAddress1.address)).equal(
				testAddress2.address
			)
		})
	})
	describe('joepegs handler', function () {
		it('Should decode payload and take correct fee (free and paid) for CALL to joepegs', async () => {
			let sender: SignerWithAddress, receiver: SignerWithAddress, extension, forumAddress
			;[sender, receiver, extension] = await hardhatEthers.getSigners()

			// Deploy mock joepegs
			const JoepegsMarket = await hardhatEthers.getContractFactory('MockJoepegsExchange')
			joepegsMarket = (await JoepegsMarket.deploy(test721.address)) as MockJoepegsExchange

			// Deploy execution manager which will format proposals to specific contracts to extract commission
			const CommissionManager = await hardhatEthers.getContractFactory('CommissionManager')
			const executionManager = await CommissionManager.deploy(sender.address)

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

			expect(await hardhatEthers.provider.getBalance(executionManager.address)).equal(0)
			// Propose + process the taker order
			await processProposal(forum, [sender], 1, {
				type: CALL,
				accounts: [joepegsMarket.address],
				amounts: [0],
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

const testTakerOrder = [false, ZERO_ADDRESS, getBigNumber(1), 1, getBigNumber(9000), '0x00']

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
