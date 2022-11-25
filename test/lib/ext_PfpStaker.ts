import { expect } from '../utils/expect'
import snapshotGasCost from '../utils/snapshotGasCost'

import { ERC1155Test, ERC721Test, ForumFactory, ForumGroup, PfpStaker } from '../../typechain'
import { CALL, EXPECTED_SHILED_PASS, PFP, ZERO_ADDRESS } from '../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { deployments, ethers, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

// TODO create a delegator util to tidy code
describe('PFP_Staking Module', () => {
	let forum: ForumGroup
	let pfpStaker: PfpStaker
	let test721: ERC721Test
	let test1155: ERC1155Test
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

		await deployments.fixture(['Forum'])
		forum = await hardhatEthers.getContract('ForumGroup')
		pfpStaker = await hardhatEthers.getContract('PfpStaker')

		// Test erc721, deploy a test 721 contract and mint a token for founder
		test721 = (await (
			await hardhatEthers.getContractFactory('ERC721Test')
		).deploy('test', 'test')) as ERC721Test
		await test721.mint(founder.address, 1)

		// Test erc1155 , deploy a test 1155 contract and mint a token for founder
		test1155 = (await (
			await hardhatEthers.getContractFactory('ERC1155Test')
		).deploy('test', 'test')) as ERC1155Test
		await test1155.mint(founder.address, 1, 1)
	})

	describe('PFP Unit Tests', () => {
		it('deploy the extension', async () => {
			await snapshotGasCost(
				await (await hardhatEthers.getContractFactory('PfpStaker')).deploy()
			)
		})
		it('revert if sender is not from address', async () => {
			await expect(
				pfpStaker.connect(founder).stakeNFT(alice.address, test721.address, 1)
			).revertedWith('Unauthorised()')
		})
		it('ERC721 revert if sender not token holder', async () => {
			await expect(
				pfpStaker.connect(alice).stakeNFT(alice.address, test721.address, 1)
			).revertedWith('NotTokenHolder()')
		})
		it('ERC1155 revert if sender is not token holder', async () => {
			await expect(
				pfpStaker.connect(alice).stakeNFT(alice.address, test1155.address, 1)
			).revertedWith('NotTokenHolder()')
		})
		it('ERC721 stake pfp', async () => {
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test721.connect(founder).approve(pfpStaker.address, 1)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test721.address, 1)

			expect((await pfpStaker.stakes(founder.address)).Nftcontract).equal(test721.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await test721.balanceOf(founder.address)).equal(0)
			expect(await test721.balanceOf(pfpStaker.address)).equal(1)
		})
		it('ERC1155 stake pfp', async () => {
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 1)

			expect((await pfpStaker.stakes(founder.address)).Nftcontract).equal(test1155.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await test1155.balanceOf(founder.address, 1)).equal(0)
			expect(await test1155.balanceOf(pfpStaker.address, 1)).equal(1)
		})
		it('ERC721 get tokenURI', async () => {
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test721.connect(founder).approve(pfpStaker.address, 1)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test721.address, 1)

			expect(await pfpStaker.getURI(founder.address, 'test')).equal(EXPECTED_SHILED_PASS)
		})
		it('ERC1155 get uri', async () => {
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 1)

			expect(await pfpStaker.getURI(founder.address, 'test')).equal('TEST URI')
		})
		it('ERC721 unstake a pfp by replacement', async () => {
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test721.connect(founder).approve(pfpStaker.address, 1)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test721.address, 1)

			// Token 1 staked
			expect((await pfpStaker.stakes(founder.address)).Nftcontract).equal(test721.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await test721.ownerOf(1)).equal(pfpStaker.address)

			// Mint a second token, we'll replace token 2 with this
			await test721.mint(founder.address, 2)

			// Approve and stake new token
			await test721.connect(founder).approve(pfpStaker.address, 2)
			await pfpStaker.connect(founder).stakeNFT(founder.address, test721.address, 2)

			// Token 2 staked, token 1 back with origional owner
			expect((await pfpStaker.stakes(founder.address)).Nftcontract).equal(test721.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(2)
			expect(await test721.ownerOf(1)).equal(founder.address)
			expect(await test721.ownerOf(2)).equal(pfpStaker.address)
		})
		it('ERC1155 unstake a pfp by replacemet', async () => {
			// Must approve staking contract to move token // TODO CONSIDER THIS DIRECT FROM DAO
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)

			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 1)

			// Token 1 staked
			expect((await pfpStaker.stakes(founder.address)).Nftcontract).equal(test1155.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(1)
			expect(await test1155.balanceOf(pfpStaker.address, 1)).equal(1)
			expect(await test1155.balanceOf(founder.address, 1)).equal(0)

			// Mint a second token, we'll replace token 1 with this
			await test1155.mint(founder.address, 2, 1)

			// Approve and stake new token
			await test1155.connect(founder).setApprovalForAll(pfpStaker.address, true)
			await pfpStaker.connect(founder).stakeNFT(founder.address, test1155.address, 2)

			// Token 2 staked, token 1 back with origional owner
			expect((await pfpStaker.stakes(founder.address)).Nftcontract).equal(test1155.address)
			expect((await pfpStaker.stakes(founder.address)).tokenId).equal(2)
			expect(await test1155.balanceOf(pfpStaker.address, 1)).equal(0)
			expect(await test1155.balanceOf(founder.address, 1)).equal(1)
			expect(await test1155.balanceOf(pfpStaker.address, 2)).equal(1)
			expect(await test1155.balanceOf(founder.address, 2)).equal(0)
		})
	})

	describe('PFP Integration Tests (linked to ForumGroup)', () => {
		let daoAddress: string
		let deployedForum: ForumGroup

		beforeEach(async () => {
			await deployments.fixture(['Forum', 'Shields'])
			masterForum = await hardhatEthers.getContract('ForumGroup')
			forumFactory = await hardhatEthers.getContract('ForumFactory')
			pfpStaker = await hardhatEthers.getContract('PfpStaker')
			const commissionManager = await hardhatEthers.getContract('CommissionManager')

			await forumFactory.connect(owner).setPfpStaker(pfpStaker.address)
			await forumFactory.connect(owner).setCommissionManager(commissionManager.address)
			await forumFactory.connect(owner).setForumMaster(masterForum.address)

			// Deploy a forum from factory and get its address
			const tx = await (
				await forumFactory.deployGroup(
					'FORUM',
					'FORUM',
					[30, 12, 50, 60],
					[founder.address, alice.address],
					[]
				)
			).wait()

			daoAddress = tx.events[2].args.forumGroup
		})
		it('Factory creates group, checks base uri', async () => {
			// Check if shield staked correctly
			expect((await pfpStaker.stakes(daoAddress)).Nftcontract).equal(ZERO_ADDRESS)
			expect((await pfpStaker.stakes(daoAddress)).tokenId).equal(0) // 2 because the beforeEach in above tests takes 1
			deployedForum = await hardhatEthers.getContractAt('ForumGroup', daoAddress)
			expect(await deployedForum.uri(2)).equal('TBC')
		})
	})
})
