import { expect } from '../../utils/expect'
import snapshotGasCost from '../../utils/snapshotGasCost'

import {
	ERC1155Test,
	ERC721Test,
	ForumFactoryV2,
	ForumGroupV2,
	PfpStakerV2,
	ShieldManager
} from '../../../typechain'
import { CALL, EXPECTED_SHILED_PASS, PFP, ZERO_ADDRESS } from '../../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { deployments, ethers, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

// TODO create a delegator util to tidy code
describe('PFP_Staking Module', () => {
	let forum: ForumGroupV2
	let pfpStaker: PfpStakerV2
	let test721: ERC721Test
	let test1155: ERC1155Test
	let masterForum: ForumGroupV2
	let forumFactory: ForumFactoryV2
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

		// Deploy PfpStaker with the test erc721 set as default (shield creator) address
		pfpStaker = (await (
			await hardhatEthers.getContractFactory('PfpStakerV2')
		).deploy(owner.address)) as PfpStakerV2
	})

	describe('PFP Unit Tests', () => {
		it('deploy the extension', async () => {
			await snapshotGasCost(
				await (await hardhatEthers.getContractFactory('PfpStakerV2')).deploy(owner.address)
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

			console.log(await pfpStaker.getURI(founder.address, 'test'))

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
		let deployedForum: ForumGroupV2

		beforeEach(async () => {
			// Deploy master ForumGroup
			masterForum = (await (
				await hardhatEthers.getContractFactory('ForumGroupV2')
			).deploy()) as ForumGroupV2

			// Deploy the Forum Factory
			forumFactory = (await (
				await hardhatEthers.getContractFactory('ForumFactoryV2')
			).deploy(owner.address, masterForum.address, ZERO_ADDRESS)) as ForumFactoryV2

			// Deploy PfpStaker with the test erc721 set as default (shield creator) address. Update factory to take this address for pfpStaker
			pfpStaker = (await (
				await hardhatEthers.getContractFactory('PfpStakerV2')
			).deploy(owner.address)) as PfpStakerV2

			await forumFactory.connect(owner).setPfpStaker(pfpStaker.address)

			// Deploy a forum from factory and get its address
			const tx = await (
				await forumFactory.deployGroup(
					'FORUM',
					'FORUM',
					[founder.address, alice.address],
					[30, 12, 50, 60],
					[]
				)
			).wait()
			console.log({ tx })

			daoAddress = tx.events[2].args.forumGroup
		})
		it('Factory creates group, checks base uri', async () => {
			// Check if shield staked correctly
			expect((await pfpStaker.stakes(daoAddress)).Nftcontract).equal(ZERO_ADDRESS)
			expect((await pfpStaker.stakes(daoAddress)).tokenId).equal(0) // 2 because the beforeEach in above tests takes 1
			deployedForum = await hardhatEthers.getContractAt('ForumGroupV2', daoAddress)
			console.log('before')
			console.log(await deployedForum.uri(2))
			expect(await deployedForum.uri(2)).equal('TBC')
		})
	})
})
