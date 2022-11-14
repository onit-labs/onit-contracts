import { expect } from '../utils/expect'

import { MEMBERSHIP, TOKEN, ZERO_ADDRESS } from '../config'
import {
	ForumGroup,
	ForumFactory,
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

const createCustomCrowdfundInput = (
	crowdfundAddress,
	marketplaceAddress,
	assetAddress,
	founderBonus,
	assetPrice
) => {
	//	Setup taker order for marketplace (joepegs) to the corwdfund contract
	const testTakerOrder = [
		false,
		crowdfundAddress,
		getBigNumber(assetPrice),
		1,
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

	// Build the payload for the taker order
	const payloadWithFunctionSelector = COMMISSION_BASED_FUNCTIONS[0] + payload.substring(2)

	// Build full crowdfund input for this order
	return {
		targetContract: marketplaceAddress,
		assetContract: assetAddress,
		deadline: 1730817411, // 05-11-2030
		tokenId: 1,
		founderBonus: founderBonus,
		groupName: 'TEST',
		symbol: 'T',
		payload: payloadWithFunctionSelector
	}
}

describe.only('Crowdfund', function () {
	let forum: ForumGroup // ForumGroup contract instance
	let forumFactory: ForumFactory // ForumFactory contract instance
	let crowdfund: ForumCrowdfund // Crowdfund contract instance
	let executionManager: CrowdfundExecutionManager // CrowdfundExecutionManager contract instance
	let joepegsHandler: JoepegsCrowdfundHandler // CrowdfundExecutionManager contract instance
	let joepegsMarket: Contract // CrowdfundExecutionManager contract instance
	let pfpStaker: Contract // pfpStaker contract instance
	let test721: ERC721Test // test721 contract instance
	let proposer: SignerWithAddress // signerA
	let alice: SignerWithAddress // signerB
	let bob: SignerWithAddress // signerC
	let crowdfundInput: any // demo input for crowdfund
	let testGroupNameHash: string // hash of test group name, used to locate crowdfun on contract

	beforeEach(async () => {
		;[proposer, alice, bob] = await hardhatEthers.getSigners()

		// Deploy contracts used in tests
		await deployments.fixture([
			'ForumCrowdfund',
			'PfpStaker',
			'CrowdfundExecutionManager',
			'JoepegsCrowdfundHandler'
		])
		forum = await hardhatEthers.getContract('ForumGroup')
		forumFactory = await hardhatEthers.getContract('ForumFactory')
		crowdfund = await hardhatEthers.getContract('ForumCrowdfund')
		executionManager = await hardhatEthers.getContract('CrowdfundExecutionManager')
		joepegsHandler = await hardhatEthers.getContract('JoepegsCrowdfundHandler')
		pfpStaker = await hardhatEthers.getContract('PfpStaker')

		// Deploy a test ERC721 contract and MockJoepegs to test full flow
		test721 = (await (
			await hardhatEthers.getContractFactory('ERC721Test')
		).deploy('test', 'test')) as ERC721Test
		const JoepegsMarket = await hardhatEthers.getContractFactory('MockJoepegsExchange')
		joepegsMarket = await JoepegsMarket.deploy(test721.address)

		// Setp deployments with correct addresses
		await forumFactory.setPfpStaker(pfpStaker.address)
		await forumFactory.setFundraiseExtension(ZERO_ADDRESS)
		await executionManager.addExecutionHandler(joepegsMarket.address, joepegsHandler.address)

		crowdfundInput = createCustomCrowdfundInput(
			crowdfund.address,
			joepegsMarket.address,
			test721.address,
			100,
			1
		)

		// Generate hash of groupname used to locate crowdfund on contract
		testGroupNameHash = ethers.utils.keccak256(
			ethers.utils.defaultAbiCoder.encode(['string'], [crowdfundInput.groupName])
		)

		// Initiate a fund used in tests below
		await crowdfund.initiateCrowdfund(crowdfundInput, { value: getBigNumber(1) })
		console.log('after: ')
	})
	it('Should initiate crowdfund and submit contribution', async function () {
		const crowdfundDetails = await crowdfund.getCrowdfund(testGroupNameHash)

		// Check initial state
		expect(crowdfundDetails.details.targetContract).to.equal(crowdfundInput.targetContract)
		expect(crowdfundDetails.details.founderBonus).to.equal(crowdfundInput.founderBonus)
		expect(crowdfundDetails.details.deadline).to.equal(crowdfundInput.deadline)
		expect(crowdfundDetails.details.groupName).to.equal(crowdfundInput.groupName)
		expect(crowdfundDetails.details.symbol).to.equal(crowdfundInput.symbol)
		expect(crowdfundDetails.contributors[0]).to.equal(proposer.address)
		//expect(crowdfundDetails.payload).to.equal(crowdfundInput.payload)

		await crowdfund.connect(alice).submitContribution(testGroupNameHash),
			{
				value: getBigNumber(1)
			}

		const crowdfundDetailsAfterSubmission = await crowdfund.getCrowdfund(testGroupNameHash)

		// Check updated state
		expect(crowdfundDetailsAfterSubmission.contributors).to.have.lengthOf(2)
		expect(crowdfundDetailsAfterSubmission.contributions).to.have.lengthOf(2)
		expect(crowdfundDetailsAfterSubmission.details.targetContract).to.equal(
			crowdfundInput.targetContract
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
	it('Should revert creating a crowdfund if a duplicate name exists', async function () {
		await expect(crowdfund.initiateCrowdfund(crowdfundInput)).to.be.revertedWith('OpenFund()')
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
	// ! need to test failure for incorrect value for nft, or general failure from marketplace call
	it('Should revert if commission is not paid', async function () {
		// Add joepegs handler and cancel the crowdfund before creating a new one with details that will fail
		await executionManager.addExecutionHandler(joepegsMarket.address, joepegsHandler.address)
		advanceTime(1730817412)
		await crowdfund.cancelCrowdfund(testGroupNameHash)

		// Below input will fail since target and asset prices are the same so commission will not be paid
		crowdfundInput = createCustomCrowdfundInput(
			crowdfund.address,
			joepegsMarket.address,
			test721.address,
			2,
			2
		)

		// Create a new crowdfund
		await crowdfund.initiateCrowdfund(crowdfundInput, { value: getBigNumber(1) })

		// Contribute so target value is reached
		await crowdfund.submitContribution(testGroupNameHash, {
			value: getBigNumber(1)
		})

		// Fail for lack of commission
		await expect(crowdfund.processCrowdfund(testGroupNameHash)).to.be.revertedWith(
			'InsufficientFunds()'
		)
	})
	it('Should process a crowdfund, and not process it twice', async function () {
		// console.log(
		// 	ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(['string'], ['crowd3']))
		// )
		// Contribute so target value is reached
		await crowdfund.submitContribution(testGroupNameHash, {
			value: getBigNumber(1)
		})

		// Process crowdfund
		const tx = await (await crowdfund.processCrowdfund(testGroupNameHash)).wait()

		// Get group deployed by crowdfund and check balance of member (with founder bonus), and that group owns asset
		const group = `0x${tx.events[1].topics[1].substring(26)}`
		const groupContract = await hardhatEthers.getContractAt('ForumGroup', group)
		expect(await groupContract.balanceOf(proposer.address, MEMBERSHIP)).to.equal(1)
		expect(await groupContract.balanceOf(proposer.address, TOKEN)).to.equal(
			getBigNumber(2)
				.mul(10000 + crowdfundInput.founderBonus)
				.div(10000)
		)
		expect(await test721.ownerOf(crowdfundInput.tokenId)).to.equal(
			ethers.utils.getAddress(groupContract.address)
		)

		// Check commission has been paid to execution manager
		expect(await hardhatEthers.provider.getBalance(executionManager.address)).to.equal(
			getBigNumber(5).div(100)
		)

		// Will fail to process a second time
		await expect(crowdfund.processCrowdfund(testGroupNameHash)).to.be.revertedWith(
			'MissingCrowdfund()'
		)
	})
	it('Should process a crowdfund with multiple members, and transfer excess funds to group', async function () {
		// Contribute so target value is reached
		await crowdfund.submitContribution(testGroupNameHash, {
			value: getBigNumber(1)
		})
		// Contribute so target value is reached
		await crowdfund.connect(alice).submitContribution(testGroupNameHash, {
			value: getBigNumber(1)
		})

		// Process crowdfund
		const tx = await (await crowdfund.processCrowdfund(testGroupNameHash)).wait()

		// Get group deployed by crowdfund and check balance of member, and that group owns asset
		const group = `0x${tx.events[2].topics[1].substring(26)}`
		const groupContract = await hardhatEthers.getContractAt('ForumGroup', group)

		expect(await groupContract.balanceOf(proposer.address, MEMBERSHIP)).to.equal(1)
		expect(await groupContract.balanceOf(proposer.address, TOKEN)).to.equal(
			getBigNumber(2).add(getBigNumber(3).mul(crowdfundInput.founderBonus).div(10000))
		)
		expect(await groupContract.balanceOf(alice.address, MEMBERSHIP)).to.equal(1)
		expect(await groupContract.balanceOf(alice.address, TOKEN)).to.equal(getBigNumber(1))
		expect(await test721.ownerOf(crowdfundInput.tokenId)).to.equal(
			ethers.utils.getAddress(groupContract.address)
		)

		// Check commission has been paid to execution manager
		expect(await hardhatEthers.provider.getBalance(executionManager.address)).to.equal(
			getBigNumber(75).div(1000)
		)
	})
	it('Should revert if founder bonus over 5, and be OK for bonus = 0', async function () {
		// Cancel the previous crowdfund
		advanceTime(1730817412)
		await crowdfund.cancelCrowdfund(testGroupNameHash)

		const crowdfundInputFailFounderBonusExceeded = createCustomCrowdfundInput(
			crowdfund.address,
			joepegsMarket.address,
			test721.address,
			600,
			1
		)

		// Contribute so target value is reached
		await expect(
			crowdfund.initiateCrowdfund(crowdfundInputFailFounderBonusExceeded, {
				value: getBigNumber(2)
			})
		).to.be.revertedWith('FounderBonusExceeded()')

		const crowdfundInputPassFounderBonusZero = createCustomCrowdfundInput(
			crowdfund.address,
			joepegsMarket.address,
			test721.address,
			0,
			1
		)

		await crowdfund.initiateCrowdfund(crowdfundInputPassFounderBonusZero, {
			value: getBigNumber(2)
		})

		// Process crowdfund
		const tx = await (await crowdfund.processCrowdfund(testGroupNameHash)).wait()

		// Get group deployed by crowdfund and check balance of member, and that group owns asset
		const group = `0x${tx.events[1].topics[1].substring(26)}`
		const groupContract = await hardhatEthers.getContractAt('ForumGroup', group)
		expect(await groupContract.balanceOf(proposer.address, MEMBERSHIP)).to.equal(1)
		expect(await groupContract.balanceOf(proposer.address, TOKEN)).to.equal(getBigNumber(2))
	})
})
