import deployFrameGenerator from '../../utils/deployFrameGenerator'
import deployTestFieldGenerator from '../../utils/deployTestFieldGenerator'
import deployTestHardwareGenerator from '../../utils/deployTestHardwareGenerator'
import { expect } from '../../utils/expect'
import { advanceTime, getBigNumber, parseEther } from '../../utils/helpers'
import { processProposal } from '../../utils/processProposal'
import snapshotGasCost from '../../utils/snapshotGasCost'

import {
	AccessManager,
	EmblemWeaver,
	ERC1155,
	ERC1155Test,
	ForumFactory,
	ForumGroup,
	FrameGenerator,
	PfpStaker,
	ShieldManager,
	TestFieldGenerator,
	TestHardwareGenerator
} from '../../../typechain'
import { CALL, EXPECTED_SHILED_PASS, PFP, ZERO_ADDRESS } from '../../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber, Contract, ethers } from 'ethers'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

// TODO create a delegator util to tidy code
describe('PFP_Staking Module', () => {
	let forum: ForumGroup
	let accessManager: AccessManager
	let pfpStaker: PfpStaker
	let testShield721: ShieldManager
	let test1155: ERC1155Test
	let frameGenerator: Contract
	let hardwareGenerator: Contract
	let fieldGenerator: Contract
	let emblemWeaver: EmblemWeaver
	let masterForum: ForumGroup
	let forumFactory: ForumFactory
	let owner: SignerWithAddress
	let founder: SignerWithAddress
	let alice: SignerWithAddress
	let bob: SignerWithAddress
	let carol: SignerWithAddress
	let tokenId: any

	beforeEach(async () => {
		;[owner, founder, alice, bob, carol] = await hardhatEthers.getSigners()

		await deployments.fixture(['Forum', 'Shields'])
		forum = await hardhatEthers.getContract('ForumGroup')

		/// ///////////////////////////////////////////////
		// TODO try to remove the below, but we need the shield manager setup somehow
		//
		frameGenerator = (await deployFrameGenerator()) as FrameGenerator
		// hardwareGenerator = (await deployHardwareGenerator()) as HardwareGenerator
		// fieldGenerator = (await deployFieldGenerator()) as FieldGenerator
		hardwareGenerator = (await deployTestHardwareGenerator()) as TestHardwareGenerator
		fieldGenerator = (await deployTestFieldGenerator()) as TestFieldGenerator

		emblemWeaver = (await (
			await hardhatEthers.getContractFactory('EmblemWeaver')
		).deploy(
			fieldGenerator.address,
			hardwareGenerator.address,
			frameGenerator.address
		)) as EmblemWeaver
		//
		/// ///////////////////////////////////////////////

		// Test erc721 , we use shields contract for convenience and mint a token for founder
		testShield721 = (await (
			await hardhatEthers.getContractFactory('ShieldManager')
		).deploy(owner.address, 'Shields', 'SHIELDS', emblemWeaver.address)) as ShieldManager
		await testShield721.setPublicMintActive(true)
		await testShield721.mintShieldPass(founder.address, {
			value: getBigNumber(0.5)
		})

		// Test erc1155 , deploy a test 1155 contract and mint a token for founder
		test1155 = (await (
			await hardhatEthers.getContractFactory('ERC1155Test')
		).deploy('test', 'test')) as ERC1155Test
		await test1155.mint(founder.address, 1, 1)

		// Deploy PfpStaker with the test erc721 set as default (shield creator) address
		pfpStaker = (await (
			await hardhatEthers.getContractFactory('PfpStakerV2')
		).deploy(owner.address, testShield721.address, ZERO_ADDRESS)) as PfpStaker
	})

	describe('PFP Unit Tests', () => {
		it('deploy the extension', async () => {
			await snapshotGasCost(
				await (
					await hardhatEthers.getContractFactory('PfpStaker')
				).deploy(owner.address, testShield721.address, ZERO_ADDRESS)
			)
		})
		it('allow owner to toggle restricted mode and revert for non owner', async () => {
			expect(await pfpStaker.restrictedContracts()).equal(true)
			await pfpStaker.connect(owner).setRestrictedContracts()
			expect(await pfpStaker.restrictedContracts()).equal(false)

			await expect(pfpStaker.connect(alice).setRestrictedContracts()).revertedWith('UNAUTHORIZED')
		})
		it('allow owner to set allowed nft contracts for pfps and revert for non owner', async () => {
			await pfpStaker.connect(owner).setEnabledContract(bob.address)
			expect(await pfpStaker.enabledPfpContracts(bob.address)).equal(true)

			await expect(pfpStaker.connect(alice).setEnabledContract(bob.address)).revertedWith(
				'UNAUTHORIZED'
			)
		})
		it('revert setting a non enabled pfp while in restricted mode', async () => {
			await test1155.mint(alice.address, 1, 1)
			await expect(
				pfpStaker.connect(alice).stakeNFT(alice.address, test1155.address, 1)
			).revertedWith('RestrictedNFT()')
		})
		it('revert if sender is not from address', async () => {
			await pfpStaker.connect(owner).setEnabledContract(testShield721.address)
			await expect(
				pfpStaker.connect(founder).stakeNFT(alice.address, testShield721.address, 1)
			).revertedWith('Unauthorised()')
		})
		it('ERC721 revert if sender not token holder', async () => {
			await pfpStaker.connect(owner).setEnabledContract(testShield721.address)
			await expect(
				pfpStaker.connect(alice).stakeNFT(alice.address, testShield721.address, 1)
			).revertedWith('NotTokenHolder()')
		})
		it('ERC1155 revert if sender is not token holder', async () => {
			await pfpStaker.connect(owner).setEnabledContract(test1155.address)
			await expect(
				pfpStaker.connect(alice).stakeNFT(alice.address, test1155.address, 1)
			).revertedWith('NotTokenHolder()')
		})
		it('ERC721 stake pfp', async () => {
			await pfpStaker.connect(owner).setEnabledContract(testShield721.address)
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await testShield721.connect(founder).approve(pfpStaker.address, 1)

			await pfpStaker.connect(founder).stakeNFT(founder.address, testShield721.address, 1)

			expect((await pfpStaker.stakes(founder.address)).NFTcontract).equal(testShield721.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await testShield721.balanceOf(founder.address)).equal(0)
			expect(await testShield721.balanceOf(pfpStaker.address)).equal(1)
		})
		it('ERC1155 stake pfp', async () => {
			await pfpStaker.connect(owner).setEnabledContract(test1155.address)
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 1)

			expect((await pfpStaker.stakes(founder.address)).NFTcontract).equal(test1155.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await test1155.balanceOf(founder.address, 1)).equal(0)
			expect(await test1155.balanceOf(pfpStaker.address, 1)).equal(1)
		})
		it('ERC721 get tokenURI', async () => {
			await pfpStaker.connect(owner).setEnabledContract(testShield721.address)
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await testShield721.connect(founder).approve(pfpStaker.address, 1)

			await pfpStaker.connect(founder).stakeNFT(founder.address, testShield721.address, 1)

			console.log(await pfpStaker.getURI(founder.address))

			expect(await pfpStaker.getURI(founder.address)).equal(EXPECTED_SHILED_PASS)
		})
		it('ERC1155 get uri', async () => {
			await pfpStaker.connect(owner).setEnabledContract(test1155.address)
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 1)

			expect(await pfpStaker.getURI(founder.address)).equal('TEST URI')
		})
		it('ERC721 unstake a pfp by replacement', async () => {
			await pfpStaker.connect(owner).setEnabledContract(testShield721.address)
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await testShield721.connect(founder).approve(pfpStaker.address, 1)

			await pfpStaker.connect(founder).stakeNFT(founder.address, testShield721.address, 1)

			// Token 1 staked
			expect((await pfpStaker.stakes(founder.address)).NFTcontract).equal(testShield721.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await testShield721.ownerOf(1)).equal(pfpStaker.address)

			// Mint a second token, we'll replace token 1 with this
			await testShield721.mintShieldPass(founder.address, {
				value: getBigNumber(0.5)
			})

			// Approve and stake new token
			await testShield721.connect(founder).approve(pfpStaker.address, 2)
			await pfpStaker.connect(founder).stakeNFT(founder.address, testShield721.address, 2)

			// Token 2 staked, token 1 back with origional owner
			expect((await pfpStaker.stakes(founder.address)).NFTcontract).equal(testShield721.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(2)
			expect(await testShield721.ownerOf(1)).equal(founder.address)
			expect(await testShield721.ownerOf(2)).equal(pfpStaker.address)
		})
		it('ERC1155 unstake a pfp by replacemet', async () => {
			await pfpStaker.connect(owner).setEnabledContract(test1155.address)
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 1)

			// Token 1 staked
			expect((await pfpStaker.stakes(founder.address)).NFTcontract).equal(test1155.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await test1155.balanceOf(pfpStaker.address, 1)).equal(1)
			expect(await test1155.balanceOf(founder.address, 1)).equal(0)

			// Mint a second token, we'll replace token 1 with this
			await test1155.mint(founder.address, 2, 1)

			// Approve and stake new token
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)
			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 2)

			// Token 2 staked, token 1 back with origional owner
			expect((await pfpStaker.stakes(founder.address)).NFTcontract).equal(test1155.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(2)
			expect(await test1155.balanceOf(pfpStaker.address, 1)).equal(0)
			expect(await test1155.balanceOf(founder.address, 1)).equal(1)
			expect(await test1155.balanceOf(pfpStaker.address, 2)).equal(1)
			expect(await test1155.balanceOf(founder.address, 2)).equal(0)
		})
	})

	describe('PFP Integration Tests (linked to ForumGroup)', () => {
		let daoAddress: string

		beforeEach(async () => {
			// Deploy master ForumGroup
			masterForum = (await (
				await hardhatEthers.getContractFactory('ForumGroup')
			).deploy()) as ForumGroup

			// Deploy the Forum Factory
			forumFactory = (await (
				await hardhatEthers.getContractFactory('ForumFactory')
			).deploy(
				owner.address,
				masterForum.address,
				ZERO_ADDRESS,
				testShield721.address
			)) as ForumFactory
			await forumFactory.connect(owner).setLaunched(true)

			// Set factory as non paying address in testShield721 - legacy roundtable naming
			await testShield721.connect(owner).setRoundtableFactory(forumFactory.address)

			// Deploy PfpStaker with the test erc721 set as default (shield creator) address. Update factory to take this address for pfpStaker
			pfpStaker = (await (
				await hardhatEthers.getContractFactory('PfpStaker')
			).deploy(owner.address, testShield721.address, forumFactory.address)) as PfpStaker

			await forumFactory.connect(owner).setPfpStaker(pfpStaker.address)

			// Deploy a forum from factory and get its address
			const tx = await (
				await forumFactory.deployGroup(
					'FORUM',
					'FORUM',
					[founder.address, alice.address],
					[30, 0, 50, 60]
				)
			).wait()
			daoAddress = tx.events[4].args.forumGroup
		})
		it('Factory creates group, mints shield, and stakes in pfpStaker', async () => {
			// Check if shield staked correctly
			expect((await pfpStaker.stakes(daoAddress)).NFTcontract).equal(testShield721.address)
			expect((await pfpStaker.stakes(daoAddress)).tokenId).equal(2) // 2 because the beforeEach in above tests takes 1
			expect(await testShield721.ownerOf(2)).equal(pfpStaker.address)

			const cont = await hardhatEthers.getContractAt('ForumGroup', daoAddress)
			//console.log(await cont.uri(1))
		})

		it('Returns initial shield to group if group stake a new one', async () => {
			// Simulate the factory minting a shield pass for the group
			const passId = await (
				await testShield721.mintShieldPass(daoAddress, {
					value: getBigNumber(0.5)
				})
			).wait()
			// console.log(passId)

			// 3 is the current tokenId
			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
				['address', 'uint256'],
				[pfpStaker.address, 3]
			)

			const approvePayload = `0x095ea7b3${payload.slice(2)}`

			await processProposal(
				await hardhatEthers.getContractAt('ForumGroup', daoAddress),
				[founder],
				1,
				{
					type: PFP,
					accounts: [testShield721.address],
					amounts: [3],
					payloads: [approvePayload]
				}
			)

			// Token 1 staked
			expect((await pfpStaker.stakes(daoAddress)).NFTcontract).equal(testShield721.address)
			expect((await pfpStaker.stakes(daoAddress)).tokenId).equal(3)
			expect(await testShield721.balanceOf(pfpStaker.address)).equal(1)
			expect(await testShield721.balanceOf(forum.address)).equal(0)
		})
		it('Allows editing shield if staked in pfp', async () => {
			// console.log({ daoAddress })
			// console.log(await testShield721.ownerOf(1))
			// console.log(await testShield721.ownerOf(2))
			// console.log(await testShield721.ownerOf(3))

			// Builds a shield with some items costing 0.1 avax
			const buildPayload =
				'0x2f7548f3000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e7000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e7000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000047ab0000000000000000000000000000000000000000000000000000000000013f6a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002'
			// console.log(await testShield721.shields(2))

			// TODO - needs tested properly. Test works in remix, but can not call contract address from hardhat
			await processProposal(
				await hardhatEthers.getContractAt('ForumGroup', daoAddress),
				[founder],
				1,
				{
					type: CALL,
					accounts: [testShield721.address],
					amounts: [getBigNumber(0.1)],
					payloads: [buildPayload]
				}
			)

			// console.log(await testShield721.shields(0))
			// console.log(await testShield721.shields(1))
			// console.log(await testShield721.shields(2))
			// console.log(await testShield721.shields(3))

			// Token 1 staked
			expect((await pfpStaker.stakes(daoAddress)).NFTcontract).equal(testShield721.address)
			expect((await pfpStaker.stakes(daoAddress)).tokenId).equal(2)
			expect(await testShield721.balanceOf(pfpStaker.address)).equal(1)
			expect(await testShield721.balanceOf(daoAddress)).equal(0)
		})
		it('Allows editing shield if staked in pfp', async () => {
			// console.log({ daoAddress })
			// console.log(await testShield721.ownerOf(1))
			// console.log(await testShield721.ownerOf(2))
			// console.log(await testShield721.ownerOf(3))

			// Builds a shield with some items costing 0.1 avax
			const buildPayload =
				'0x2f7548f3000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e7000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e700000000000000000000000000000000000000000000000000000000000003e7000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000047ab0000000000000000000000000000000000000000000000000000000000013f6a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002'
			// console.log(await testShield721.shields(2))

			// TODO - needs tested properly. Test works in remix, but can not call contract address from hardhat
			await processProposal(
				await hardhatEthers.getContractAt('ForumGroup', daoAddress),
				[founder],
				1,
				{
					type: CALL,
					accounts: [testShield721.address],
					amounts: [getBigNumber(0.1)],
					payloads: [buildPayload]
				}
			)

			// console.log(await testShield721.shields(0))
			// console.log(await testShield721.shields(1))
			// console.log(await testShield721.shields(2))
			// console.log(await testShield721.shields(3))

			// Token 1 staked
			expect((await pfpStaker.stakes(daoAddress)).NFTcontract).equal(testShield721.address)
			expect((await pfpStaker.stakes(daoAddress)).tokenId).equal(2)
			expect(await testShield721.balanceOf(pfpStaker.address)).equal(1)
			expect(await testShield721.balanceOf(daoAddress)).equal(0)
		})
	})
})
