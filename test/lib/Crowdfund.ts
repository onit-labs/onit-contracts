import { expect } from '../utils/expect'

import { TOKEN, ZERO_ADDRESS } from '../config'
import {
	ForumGroupV2,
	ForumFactoryV2,
	ForumCrowdfund,
	CrowdfundExecutionManager,
	JoepegsCrowdfundHandler,
	ERC721,
	ERC721Test
} from '../../typechain'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber, Contract, ContractFactory, ethers, Signer } from 'ethers'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'
import { advanceTime, getBigNumber } from '../utils/helpers'
import { COMMISSION_BASED_FUNCTIONS, COMMISSION_FREE_FUNCTIONS } from '../../config'
import { toUtf8 } from 'web3-utils'

// Dummy maker order to provide input to a test
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

describe.only('Crowdfund', function () {
	let forum: ForumGroupV2 // ForumGroup contract instance
	let forumFactory: ForumFactoryV2 // ForumFactory contract instance
	let crowdfund: ForumCrowdfund // Crowdfund contract instance
	let executionManager: CrowdfundExecutionManager // CrowdfundExecutionManager contract instance
	let joepegsHandler: JoepegsCrowdfundHandler // CrowdfundExecutionManager contract instance
	let joepegsMarket: Contract // CrowdfundExecutionManager contract instance
	let pfpStaker: Contract // pfpStaker contract instance
	let test721: ERC721Test // test721 contract instance
	let proposer: SignerWithAddress // signerA
	let alice: SignerWithAddress // signerB
	let bob: SignerWithAddress // signerC
	let crowdsaleInput: any // demo input for crowdsale
	let testGroupNameHash: string // hash of test group name, used to locate crowdfun on contract

	beforeEach(async () => {
		;[proposer, alice, bob] = await hardhatEthers.getSigners()

		// Deploy contracts used in tests
		await deployments.fixture(['Forum', 'Shields'])
		forum = await hardhatEthers.getContract('ForumGroupV2')
		forumFactory = await hardhatEthers.getContract('ForumFactoryV2')
		crowdfund = await hardhatEthers.getContract('ForumCrowdfund')
		executionManager = await hardhatEthers.getContract('CrowdfundExecutionManager')
		joepegsHandler = await hardhatEthers.getContract('JoepegsCrowdfundHandler')
		pfpStaker = await hardhatEthers.getContract('PfpStaker')

		console.log('Forum address: ', forum.address)
		console.log('ForumFactory address: ', forumFactory.address)
		console.log('ForumCrowdfund address: ', crowdfund.address)
		console.log('CrowdfundExecutionManager address: ', executionManager.address)
		console.log('PfpStaker address: ', pfpStaker.address)

		// Deploy a test ERC721 contract and MockJoepegs to test full flow
		//
		// Test erc721
		test721 = (await (
			await hardhatEthers.getContractFactory('ERC721Test')
		).deploy('test', 'test')) as ERC721Test
		//
		// Mock joepegs
		const JoepegsMarket = await hardhatEthers.getContractFactory('MockJoepegsExchange')
		joepegsMarket = await JoepegsMarket.deploy(test721.address)

		// Setp deployments with correct addresses
		await forumFactory.setPfpStaker(pfpStaker.address)
		await forumFactory.setFundraiseExtension(ZERO_ADDRESS)

		// Generic input call to some address
		crowdsaleInput = {
			targetContract: forumFactory.address,
			assetContract: forumFactory.address,
			deadline: 1730817411, // 05-11-2030
			tokenId: 1,
			targetPrice: getBigNumber(2),
			groupName: 'TEST',
			symbol: 'T',
			payload: ethers.utils.toUtf8Bytes(
				'0x5d150a9500000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000003f48000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033000000000000000000000000000000000000000000000000000000000000003400000000000000000000000000000000000000000000000000000000000000066c6567656e64000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000064c4547454e4400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000adcc9add0b124cd933bfed9c7e53f520933d0fb4'
			)
		}

		// Generate hash of groupname used to locate crowdfund on contract
		testGroupNameHash = ethers.utils.keccak256(
			ethers.utils.defaultAbiCoder.encode(['string'], [crowdsaleInput.groupName])
		)
		console.log('testGroupNameHash: ', testGroupNameHash)

		// Initiate a fund used in tests below
		await crowdfund.initiateCrowdfund(crowdsaleInput, { value: getBigNumber(1) })
		console.log('after: ')
	})
	it('Should initiate crowdsale and submit contribution', async function () {
		const crowdfundDetails = await crowdfund.getCrowdfund(testGroupNameHash)

		// Check initial state
		expect(crowdfundDetails.details.targetContract).to.equal(crowdsaleInput.targetContract)
		expect(crowdfundDetails.details.targetPrice).to.equal(crowdsaleInput.targetPrice)
		expect(crowdfundDetails.details.deadline).to.equal(crowdsaleInput.deadline)
		expect(crowdfundDetails.details.groupName).to.equal(crowdsaleInput.groupName)
		expect(crowdfundDetails.details.symbol).to.equal(crowdsaleInput.symbol)
		expect(crowdfundDetails.contributors[0]).to.equal(proposer.address)
		//expect(crowdfundDetails.payload).to.equal(crowdsaleInput.payload)

		await crowdfund.connect(alice).submitContribution(testGroupNameHash),
			{
				value: getBigNumber(1)
			}

		const crowdfundDetailsAfterSubmission = await crowdfund.getCrowdfund(testGroupNameHash)

		// Check updated state
		console.log(crowdfundDetailsAfterSubmission.contributors)
		console.log(crowdfundDetailsAfterSubmission.contributions)
		expect(crowdfundDetailsAfterSubmission.contributors).to.have.lengthOf(2)
		expect(crowdfundDetailsAfterSubmission.contributions).to.have.lengthOf(2)
		expect(crowdfundDetailsAfterSubmission.details.targetContract).to.equal(
			crowdsaleInput.targetContract
		)
	})
	it('Should submit second contribution', async function () {
		const crowdfundDetails = await crowdfund.getCrowdfund(testGroupNameHash)

		// Check initial state
		expect(crowdfundDetails.contributors).to.have.lengthOf(1)
		expect(crowdfundDetails.contributors[0]).to.equal(proposer.address)
		expect(crowdfundDetails.contributions[0]).to.equal(getBigNumber(1))

		await crowdfund.submitContribution(testGroupNameHash, {
			value: getBigNumber(1)
		})

		const crowdfundDetailsAfterSubmission = await crowdfund.getCrowdfund(testGroupNameHash)

		// Check updated state
		expect(crowdfundDetailsAfterSubmission.contributors).to.have.lengthOf(1)
		expect(crowdfundDetailsAfterSubmission.contributors[0]).to.equal(proposer.address)
		expect(crowdfundDetailsAfterSubmission.contributions[0]).to.equal(getBigNumber(2))
	})
	// TODO need a check for previously deployed group with same name - create2 will fail, we should catch this
	it('Should revert creating a crowdsale if a duplicate name exists', async function () {
		await expect(crowdfund.initiateCrowdfund(crowdsaleInput)).to.be.revertedWith('OpenFund()')
	})
	it.skip('Should revert submitting a contribution if no fund exists, over 12 people, or incorrect value', async function () {
		// Check if fund already exists
		await expect(
			crowdfund.submitContribution(
				ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(['string'], ['WRONG']))
			)
		).to.be.revertedWith('MissingCrowdfund()')

		// Test limit beyond 100
		for (let i = 0; i < 102; i++) {
			const wallet = ethers.Wallet.createRandom()
			const w = wallet.connect(hardhatEthers.provider)
			// Send eth
			proposer.sendTransaction({
				to: w.address,
				value: ethers.utils.parseEther('1')
			})
			if (i < 99) {
				await crowdfund.connect(w).submitContribution(testGroupNameHash, {
					value: ethers.utils.parseEther('0.0000000000001')
				})
			} else {
				await expect(
					crowdfund.connect(w).submitContribution(testGroupNameHash, {
						value: 1
					})
				).to.be.revertedWith('MemberLimitReached()')
			}
		}
	})
	it('Should cancel a crowdfund and revert if not cancellable', async function () {
		// Can not cancel before deadline
		await expect(crowdfund.cancelCrowdfund(testGroupNameHash)).to.be.revertedWith('OpenFund()')

		advanceTime(1730817412)

		// Cancel the crowdfund and check the balance has been returned
		const bal1 = await hardhatEthers.provider.getBalance(proposer.address)
		await crowdfund.cancelCrowdfund(testGroupNameHash)
		const bal2 = await hardhatEthers.provider.getBalance(proposer.address)
		expect(bal2).to.be.gt(bal1)

		// Check the contributions mapping has been cleared
		const crowdfundDetails = await crowdfund.getCrowdfund(testGroupNameHash)

		expect(crowdfundDetails.contributors).to.have.lengthOf(0)
		expect(crowdfundDetails.contributions).to.have.lengthOf(0)
	})
	it('Should revert if trying to process a fund which hasnt hit its target', async function () {
		await expect(crowdfund.processCrowdfund(testGroupNameHash)).to.be.revertedWith(
			'InsufficientFunds()'
		)
	})
	it.only('Should process a crowdfund, and not process it twice', async function () {
		// Add joepegs handler and cancel the crowdfund before creating a new one with joepegs order
		await executionManager.addExecutionHandler(joepegsMarket.address, joepegsHandler.address)
		advanceTime(1730817412)
		await crowdfund.cancelCrowdfund(testGroupNameHash)

		//	Setup taker order for joepegs to the corwdfund contract
		const testTakerOrder = [
			false,
			crowdfund.address,
			getBigNumber(2),
			getBigNumber(1),
			getBigNumber(9000),
			'0x00'
		]
		// Create a taker order
		const payload = hardhatEthers.utils.defaultAbiCoder.encode(
			[
				'(bool,address,uint256,uint256,uint256,bytes)',
				'(bool,address,address,uint256,uint256,uint256,address,address,uint256,uint256,uint256,uint256,bytes,uint8,bytes32,bytes32)'
			],
			[testTakerOrder, testMakerOrder]
		)
		console.log({ payload })

		// Build the payload for the taker order
		const payloadWithFunctionSelector = COMMISSION_BASED_FUNCTIONS[0] + payload.substring(2)
		console.log({ payloadWithFunctionSelector })
		// Build full crowdfund input for this order
		crowdsaleInput = {
			targetContract: joepegsMarket.address,
			assetContract: test721.address,
			deadline: 1730817411, // 05-11-2030
			tokenId: 1,
			targetPrice: getBigNumber(2),
			groupName: 'TEST',
			symbol: 'T',
			payload: payloadWithFunctionSelector
		}

		await crowdfund.initiateCrowdfund(crowdsaleInput, { value: getBigNumber(1) })

		// Contribute so target value is reached
		await crowdfund.submitContribution(testGroupNameHash, {
			value: getBigNumber(1)
		})
		// get balance
		console.log((await hardhatEthers.provider.getBalance(proposer.address)).toString())

		// Process crowdfund
		const tx = await (await crowdfund.processCrowdfund(testGroupNameHash)).wait()

		// Get group deployed by crowdfund and check balance of member
		const group = `0x${tx.events[1].topics[1].substring(26)}`
		const groupContract = await hardhatEthers.getContractAt('ForumGroupV2', group)
		expect(await groupContract.balanceOf(proposer.address, 0)).to.equal(1)

		// ! check commission

		// Will fail to process a second time as the balances will be cleared
		await expect(crowdfund.processCrowdfund(testGroupNameHash)).to.be.revertedWith(
			'InsufficientFunds()'
		)
	})
})
