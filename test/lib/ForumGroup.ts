import { createSignature } from '../utils/createSignature'
import { expect } from '../utils/expect'
import { findPrivateKey } from '../utils/hardhat-keys'
import { advanceTime, getBigNumber } from '../utils/helpers'
import { processProposal } from '../utils/processProposal'

import { ERC721Test, ForumGroup } from '../../typechain'

import {
	ALLOW_CONTRACT_SIG,
	BURN,
	CALL,
	EXTENSION,
	MEMBER_LIMIT,
	MEMBER,
	MEMBERSHIP,
	MINT,
	PAUSE,
	SIMPLE_MAJORITY,
	TOKEN,
	TOKEN_MAJORITY,
	TYPE,
	VPERIOD,
	ZERO_ADDRESS
} from '../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { deployments, ethers, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

/// @dev In tests where the user requires tokens you will find the 'address[] extensions' field
///			 set to [proposer.address]. This is to simplify minting tokens for that address since
///			 the mintShares function is modified with onlyExtension.

describe('Forum Multisig  Setup and Functions', function () {
	// let Forum: any // ForumGroup contract
	let forum: ForumGroup // ForumGroup contract instance
	let owner: SignerWithAddress // signer
	let proposer: SignerWithAddress // signerA
	let alice: SignerWithAddress // signerB
	let bob: SignerWithAddress // signerC
	let test721: ERC721Test // ERC721Test contract instance

	beforeEach(async () => {
		;[owner, proposer, alice, bob] = await hardhatEthers.getSigners()

		// TODO this is very slow, should find workaround for Initilized() error
		await hardhatEthers.provider.send('hardhat_reset', [])

		// Similar to deploying the master forum multisig
		await deployments.fixture(['Forum'])
		forum = await hardhatEthers.getContract('ForumGroup')

		// Test erc721, deploy a test 721 contract and mint a token for founder
		test721 = (await (
			await hardhatEthers.getContractFactory('ERC721Test')
		).deploy('test', 'test')) as ERC721Test
	})
	describe('Init', function () {
		it('Should initialize with correct params', async function () {
			await forum.init(
				'forum',
				'T',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 52]
			)

			expect(await forum.name()).equal('forum')
			expect(await forum.symbol()).equal('T')
			expect(await forum.docs()).equal('')
			expect(await forum.paused()).equal(true)
			expect(await forum.balanceOf(proposer.address, 0)).equal(1)
			expect(await forum.votingPeriod()).equal(30)
			expect(await forum.memberLimit()).equal(12)
			expect(await forum.memberVoteThreshold()).equal(50)
			expect(await forum.tokenVoteThreshold()).equal(52)
			expect(await forum.proposalVoteTypes(0)).equal(0)
			expect(await forum.proposalVoteTypes(1)).equal(0)
			expect(await forum.proposalVoteTypes(2)).equal(0)
			expect(await forum.proposalVoteTypes(3)).equal(0)
			expect(await forum.proposalVoteTypes(4)).equal(0)
			expect(await forum.proposalVoteTypes(5)).equal(0)
			expect(await forum.proposalVoteTypes(6)).equal(0)
			expect(await forum.proposalVoteTypes(7)).equal(0)
			expect(await forum.proposalVoteTypes(8)).equal(0)
			expect(await forum.proposalVoteTypes(9)).equal(0)
			expect(await forum.proposalVoteTypes(10)).equal(0)
			expect(await forum.proposalVoteTypes(11)).equal(0)
			expect(await forum.proposalVoteTypes(12)).equal(0)
			expect(await forum.proposalVoteTypes(13)).equal(0)
		})
		it('distribute shield to new member on mint', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			// members should have MEMBERSHIP before shield is created
			expect(await forum.balanceOf(proposer.address, MEMBERSHIP)).equal(1)

			await processProposal(forum, [proposer], 1, {
				type: MINT,
				accounts: [alice.address],
				amounts: [getBigNumber(1000)],
				payloads: [0x00]
			})
			expect(await forum.balanceOf(alice.address, MEMBERSHIP)).equal(1)
		})
		it('Should revert if initialization gov settings exceed bounds', async function () {
			await expect(
				forum.init(
					'FORUM',
					'FORUM',
					[proposer.address],
					[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
					[30, 101, 1, 60]
				)
			).revertedWith('MemberLimitExceeded()')
			await expect(
				forum.init(
					'FORUM',
					'FORUM',
					[proposer.address],
					[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
					[30, 0, 1, 60]
				)
			).revertedWith('MemberLimitExceeded()')
			await expect(
				forum.init(
					'FORUM',
					'FORUM',
					[proposer.address],
					[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
					[30, 12, 0, 60]
				)
			).revertedWith('VoteThresholdBounds()')
			await expect(
				forum.init(
					'FORUM',
					'FORUM',
					[proposer.address],
					[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
					[30, 12, 101, 60]
				)
			).revertedWith('VoteThresholdBounds()')
			await expect(
				forum.init(
					'FORUM',
					'FORUM',
					[proposer.address],
					[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
					[30, 12, 60, 101]
				)
			).revertedWith('VoteThresholdBounds()')
		})
		it('Should revert if already initialized', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[bob.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 60, 52]
			)
			await expect(
				forum.init(
					'FORUM',
					'FORUM',
					[bob.address],
					[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
					[30, 12, 60, 52]
				)
			).revertedWith('Initialized()')
		})
	})

	describe('Proposals', function () {
		// ! consider this check
		it("Should revert if proposal arrays don't match", async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[bob.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 60, 52]
			)
			await expect(
				forum
					.connect(proposer)
					.propose(0, [bob.address, alice.address], [getBigNumber(1000)], [0x00])
			).revertedWith('NoArrayParity()')
		})
		it('Should revert if period proposal is for null or longer than year', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[bob.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 60, 52]
			)
			// normal
			await forum.connect(proposer).propose(3, [bob.address], [9000], [0x00])
			await expect(
				forum.connect(proposer).propose(3, [bob.address], [0], [0x00])
			).revertedWith('PeriodBounds()')
			await expect(
				forum.connect(proposer).propose(3, [bob.address], [31536001], [0x00])
			).revertedWith('PeriodBounds()')
		})
		it('Should revert if membership vote proposal is for greater than 100 or 0', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[bob.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			// normal
			await forum.connect(proposer).propose(5, [bob.address], [50], [0x00])
			await expect(
				forum.connect(proposer).propose(5, [bob.address], [101], [0x00])
			).revertedWith('VoteThresholdBounds()')
			await expect(
				forum.connect(proposer).propose(5, [bob.address], [0], [0x00])
			).revertedWith('VoteThresholdBounds()')
		})
		it("Should revert if type proposal has proposal type greater than 13, vote type greater than 2, or setting length isn't 2", async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[bob.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			// normal
			await forum
				.connect(proposer)
				.propose(7, [bob.address, alice.address], [0, 0], [0x00, 0x00])
			await expect(
				forum
					.connect(proposer)
					.propose(7, [bob.address, alice.address], [14, 2], [0x00, 0x00])
			).revertedWith('TypeBounds()')
			await expect(
				forum
					.connect(proposer)
					.propose(7, [bob.address, alice.address], [0, 3], [0x00, 0x00])
			).revertedWith('TypeBounds()')
			await expect(
				forum
					.connect(proposer)
					.propose(
						7,
						[proposer.address, bob.address, alice.address],
						[0, 1, 0],
						[0x00, 0x00, 0x00]
					)
			).revertedWith('TypeBounds()')
		})
		it('Should forbid processing a non-existent proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await expect(
				forum.processProposal(2, [
					{
						v: 1,
						r: '0x0000000000000000000000000000000000000000000000000000000000000000',
						s: '0x0000000000000000000000000000000000000000000000000000000000000000'
					}
				])
			).revertedWith('NotCurrentProposal()')
		})
		it('Should forbid processing a proposal that was already processed', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			await processProposal(forum, [proposer], 1, {
				type: MINT,
				accounts: [alice.address],
				amounts: [getBigNumber(1000)],
				payloads: [0x00]
			})
			await expect(
				forum.processProposal(1, [
					{
						v: 1,
						r: '0x0000000000000000000000000000000000000000000000000000000000000000',
						s: '0x0000000000000000000000000000000000000000000000000000000000000000'
					}
				])
			).revertedWith('NotCurrentProposal()')
		})
		it('Should forbid a member from voting again on proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			await forum
				.connect(proposer)
				.propose(MINT, [proposer.address], [getBigNumber(1000)], [0x00])

			// Submit the same sig multiple times and expect this to fail
			const proposerSig = await createSignature(0, forum, proposer, {
				proposal: 1
			})
			await expect(forum.processProposal(1, [proposerSig, proposerSig])).revertedWith(
				'SignatureError()'
			)
		})
		// ! consider this
		it.skip('Should forbid voting after period ends - skipped, no hard deadline, instead encourage deletion of old proposals', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await forum
				.connect(proposer)
				.propose(MINT, [proposer.address], [getBigNumber(1000)], [0x00])
			await advanceTime(35)
			const proposerSig = await createSignature(0, forum, proposer, {
				proposal: 1
			})
			await expect(forum.processProposal(1, [proposerSig])).revertedWith('NotVoteable()')
		})
		it('Should forbid changing member limit beyond bounds, or to below member count', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			// Add member so member count is 2
			await forum
				.connect(proposer)
				.propose(MINT, [alice.address], [getBigNumber(1000)], [0x00])
			const proposerSig = await createSignature(0, forum, proposer, {
				proposal: 1
			})
			await forum.processProposal(1, [proposerSig])

			// Fail to change member limit to 1
			await expect(
				forum
					.connect(proposer)
					.propose(MEMBER_LIMIT, [ZERO_ADDRESS], [getBigNumber(1)], [0x00])
			).revertedWith('MemberLimitExceeded()')

			// Fail to change member limit to 101
			await expect(
				forum
					.connect(proposer)
					.propose(MEMBER_LIMIT, [ZERO_ADDRESS], [getBigNumber(101)], [0x00])
			).revertedWith('MemberLimitExceeded()')
		})
		it('Should process membership proposal and revert if too many added', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 2, 50, 60]
			)
			await processProposal(forum, [proposer], 1, {
				type: MINT,
				accounts: [alice.address],
				amounts: [getBigNumber(1000)],
				payloads: [0x00]
			})
			await expect(
				processProposal(forum, [proposer], 1, {
					type: MINT,
					accounts: [bob.address],
					amounts: [getBigNumber(1000)],
					payloads: [0x00]
				})
			).revertedWith('MemberLimitExceeded()')
			expect(await forum.balanceOf(alice.address, TOKEN)).equal(getBigNumber(1000))
		})
		it('Should process voting period proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			expect(await forum.votingPeriod()).equal(30)
			await processProposal(forum, [proposer], 1, {
				type: 3,
				accounts: [proposer.address],
				amounts: [90],
				payloads: [0x00]
			})
			expect(await forum.votingPeriod()).equal(90)
		})
		it('Should process member limit proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			await processProposal(forum, [proposer], 1, {
				type: MEMBER_LIMIT,
				accounts: [ZERO_ADDRESS],
				amounts: [13],
				payloads: [0x00]
			})
			expect(await forum.memberLimit()).equal(13)
		})
		it('Should process tokenVoteThreshold proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await processProposal(forum, [proposer], 1, {
				type: 6,
				accounts: [proposer.address],
				amounts: [52],
				payloads: [0x00]
			})
			expect(await forum.tokenVoteThreshold()).equal(52)
		})
		it('Should process type proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await processProposal(forum, [proposer], 1, {
				type: 7,
				accounts: [proposer.address, proposer.address],
				amounts: [0, 2],
				payloads: [0x00, 0x00]
			})
			expect(await forum.proposalVoteTypes(0)).equal(2)
		})
		it('Should process pause proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await processProposal(forum, [proposer], 1, {
				type: 8,
				accounts: [proposer.address],
				amounts: [0],
				payloads: [0x00]
			})

			expect(await forum.paused()).equal(false)
		})
		it('Should process extension proposal - General', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			// Exact addresss does not matter, we use alice as an example
			await processProposal(forum, [proposer], 1, {
				type: 9,
				accounts: [alice.address],
				amounts: [0],
				payloads: [0x00]
			})
			expect(await forum.extensions(alice.address)).equal(false)
		})
		it('Should toggle extension proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			// Exact addresss does not matter, we use alice as an example
			await processProposal(forum, [proposer], 1, {
				type: 9,
				accounts: [alice.address],
				amounts: [1],
				payloads: [0x00]
			})
			expect(await forum.extensions(alice.address)).equal(true)
		})
		it('Should process escape proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await forum
				.connect(proposer)
				.propose(0, [proposer.address], [getBigNumber(1000)], [0x00])

			await forum.connect(proposer).propose(0, [proposer.address], [getBigNumber(99)], [0x00])
			const proposerSig2 = await createSignature(0, forum, proposer, {
				proposal: 2
			})

			await forum.connect(proposer).propose(10, [proposer.address], [2], [0x00])

			await advanceTime(35)
			await forum.processProposal(2, [proposerSig2])

			// Proposal #1 remains intact
			expect(await forum.proposals(1).creationTime).not.equal(0)
			// Proposal #2 deleted
			expect((await forum.proposals(2)).creationTime).equal(0)
			// Proposal #3 processed (deleted)
			expect((await forum.proposals(3)).creationTime).not.equal(0)
		})
		it('Should process docs proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			const byteArr = hardhatEthers.utils.toUtf8Bytes('hello@abcd.com')

			await processProposal(forum, [proposer], 1, {
				type: 11,
				accounts: [ZERO_ADDRESS],
				amounts: [0],
				payloads: [byteArr]
			})
			expect(await forum.docs()).equal('hello@abcd.com')
		})
		it('Should process a proposal before previous processes', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			await forum
				.connect(proposer)
				.propose(0, [proposer.address], [getBigNumber(1000)], [0x00])
			const proposerSig1 = await createSignature(0, forum, proposer, {
				proposal: 1
			})

			await forum.connect(proposer).propose(0, [proposer.address], [getBigNumber(99)], [0x00])
			const proposerSig2 = await createSignature(0, forum, proposer, {
				proposal: 2
			})

			expect(await forum.processProposal(2, [proposerSig2]))
			expect(await forum.processProposal(1, [proposerSig1]))

			// // setup 1
			// await forum.connect(proposer).propose(0, [proposer.address], [getBigNumber(1000)], [0x00])
			// await forum.connect(proposer).vote(1)
			// await advanceTime(35)

			// // setup 2
			// await forum.connect(proposer).propose({
			// 	type: 0,
			// 	accounts: [proposer.address],
			// 	amounts: [getBigNumber(1000)],
			// 	payloads: [0x00]
			// })
			// await forum.connect(proposer).vote(2)

			// // process 1 then 2
			// await forum.processProposal(1)
			// await forum.processProposal(2)
		})
		it('Should process burn (eviction) proposal', async function () {
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await processProposal(forum, [proposer], 1, {
				type: 1,
				accounts: [proposer.address],
				amounts: [0],
				payloads: [0x00]
			})
			expect(await forum.balanceOf(proposer.address, TOKEN)).equal(0)
		})
		it('Should process contract call proposal - Single', async function () {
			// Deploy execution manager which will format proposals to specific contracts to extract commission
			const CommissionManager = await hardhatEthers.getContractFactory('CommissionManager')
			const executionManager = await CommissionManager.deploy(proposer.address)

			// Set the handler in the execution manager
			await executionManager.connect(proposer).toggleNonCommissionContract(test721.address)

			let payload = test721.interface.encodeFunctionData('mint', [alice.address, 1])
			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, executionManager.address, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)
			await processProposal(forum, [proposer], 1, {
				type: CALL,
				accounts: [test721.address],
				amounts: [0],
				payloads: [payload]
			})
			expect(await test721.balanceOf(alice.address)).equal(1)
		})
		it('Should process contract call proposal - Multiple', async function () {
			// Deploy execution manager which will format proposals to specific contracts to extract commission
			const CommissionManager = await hardhatEthers.getContractFactory('CommissionManager')
			const executionManager = await CommissionManager.deploy(proposer.address)

			await forum.init(
				'FORUM',
				'FORUM',
				[proposer.address],
				[ZERO_ADDRESS, executionManager.address, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			// Send Eth to forum
			proposer.sendTransaction({
				to: forum.address,
				value: getBigNumber(10)
			})

			// Create first payload from shield manager
			let payload1 = test721.interface.encodeFunctionData('mint', [alice.address, 1])

			// Instantiate 2nd contract and make payload
			let Test1155 = await hardhatEthers.getContractFactory('ERC1155Test')
			let test1155 = await Test1155.deploy('TABLE', 'TABLE')
			await test1155.deployed()
			//await test1155.init('TABLE', 'TABLE')
			let payload2 = test1155.interface.encodeFunctionData('mint', [
				alice.address,
				1,
				getBigNumber(5)
			])

			// Set the handler in the execution manager for both targets
			await executionManager.connect(proposer).toggleNonCommissionContract(test721.address)
			await executionManager.connect(proposer).toggleNonCommissionContract(test1155.address)

			await processProposal(forum, [proposer], 1, {
				type: CALL,
				accounts: [test721.address, test1155.address],
				amounts: [getBigNumber(0.5), getBigNumber(0)],
				payloads: [payload1, payload2]
			})

			expect(await test721.ownerOf(1)).equal(alice.address)
			expect(await test1155.balanceOf(alice.address, 1)).equal(getBigNumber(5))
		})
	})

	describe('Token Management', function () {
		let sender, receiver, extension, nonextension

		beforeEach(async function () {
			;[sender, receiver, extension, nonextension] = await hardhatEthers.getSigners()

			await forum.init(
				'FORUM',
				'FORUM',
				[sender.address, receiver.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
			await processProposal(forum, [sender], 1, {
				type: EXTENSION,
				accounts: [extension.address],
				amounts: [1],
				payloads: [0x00]
			})

			// Mint proposer and alice shares
			await forum.connect(extension).mintShares(sender.address, TOKEN, getBigNumber(10))
			await forum.connect(extension).mintShares(receiver.address, TOKEN, getBigNumber(10))

			// Flip pause to allow transfers
			await processProposal(forum, [sender], 2, {
				type: PAUSE,
				accounts: [ZERO_ADDRESS],
				amounts: [1],
				payloads: [0x00]
			})
		})

		it('Should allow a member to transfer shares', async function () {
			await forum.safeTransferFrom(
				sender.address,
				receiver.address,
				TOKEN,
				getBigNumber(10),
				'0x00'
			)
			expect(await forum.balanceOf(sender.address, TOKEN)).equal(getBigNumber(0))
			expect(await forum.balanceOf(receiver.address, TOKEN)).equal(getBigNumber(20))
			// console.log(await forum.balanceOf(sender.address))
			// console.log(await forum.balanceOf(receiver.address))
		})
		// Reverting which is expected, but can catch error in hardhat - checked on fuji
		it.skip('Should not allow a member to transfer excess shares - checked on fuji', async function () {
			await expect(
				forum
					.connect(receiver)
					.safeTransferFrom(
						receiver.address,
						sender.address,
						TOKEN,
						getBigNumber(21),
						'0x00'
					)
			).reverted()
		})
		it('Should allow a member to approve transfers', async function () {
			await forum.setApprovalForAll(receiver.address, true)
			expect(await forum.isApprovedForAll(sender.address, receiver.address)).equal(true)
		})
		it('Should allow an approved account to transfer (safeTransferFrom)', async function () {
			await forum.setApprovalForAll(receiver.address, true)
			await forum
				.connect(receiver)
				.safeTransferFrom(sender.address, receiver.address, TOKEN, getBigNumber(10), '0x00')
			expect(await forum.balanceOf(sender.address, TOKEN)).equal(getBigNumber(0))
			expect(await forum.balanceOf(receiver.address, TOKEN)).equal(getBigNumber(20))
		})
		// Reverting which is expected, but can catch error in hardhat - checked on fuji
		it.skip('Should not allow an account to transfer (safeTransferFrom) beyond approval - checked on fuji', async function () {
			await forum.setApprovalForAll(receiver.address, true)
			await expect(
				await forum
					.connect(receiver)
					.safeTransferFrom(
						sender.address,
						receiver.address,
						TOKEN,
						getBigNumber(30),
						'0x00'
					)
			).reverted()
		})
		it('Should not allow an approved account to transfer (safeTransferFrom) if paused', async function () {
			// Re enable pause for this test
			await processProposal(forum, [sender], 3, {
				type: PAUSE,
				accounts: [ZERO_ADDRESS],
				amounts: [1],
				payloads: [0x00]
			})
			await forum.connect(sender).setApprovalForAll(receiver.address, true)
			await expect(
				forum
					.connect(receiver)
					.safeTransferFrom(
						sender.address,
						receiver.address,
						TOKEN,
						getBigNumber(10),
						'0x00'
					)
			).revertedWith('Paused()')
		})
		it('Should not allow a member to transfer (safeTransferFrom) shares if paused', async function () {
			// Re enable pause for this test
			await processProposal(forum, [sender], 3, {
				type: PAUSE,
				accounts: [ZERO_ADDRESS],
				amounts: [1],
				payloads: [0x00]
			})

			await expect(
				forum
					.connect(sender)
					.safeTransferFrom(
						sender.address,
						receiver.address,
						TOKEN,
						getBigNumber(1),
						'0x00'
					)
			).revertedWith('Paused()')
		})
	})

	describe('Multisig Management', function () {
		let sender: SignerWithAddress,
			receiver: SignerWithAddress,
			extension,
			nonextension,
			forumAddress
		beforeEach(async function () {
			;[sender, receiver, extension, nonextension] = await hardhatEthers.getSigners()

			await forum.init(
				'FORUM',
				'FORUM',
				[sender.address, receiver.address, alice.address],
				[ZERO_ADDRESS, ZERO_ADDRESS, ZERO_ADDRESS],
				[30, 12, 50, 60]
			)

			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
			await processProposal(forum, [receiver, sender], 1, {
				type: EXTENSION,
				accounts: [extension.address],
				amounts: [1],
				payloads: [0x00]
			})

			// Mint sender and receiver shares (sender gets 11 to allow for majority vote)
			await forum.connect(extension).mintShares(sender.address, TOKEN, getBigNumber(11))
			await forum.connect(extension).mintShares(receiver.address, TOKEN, getBigNumber(10))
		})
		it('should count votes correctly for member vote', async function () {
			let result

			expect(await forum.proposalVoteTypes(TYPE)).equal(MEMBER)

			// This tests a member vote
			// Should not pass as it did not get enough votes
			result = await processProposal(forum, [receiver], 2, {
				type: VPERIOD,
				accounts: [ZERO_ADDRESS],
				amounts: [100],
				payloads: [0x00]
			})
			expect(result.didProposalPass).equal(false)

			// Should pass as this time it has enough votes
			result = await processProposal(forum, [receiver, sender], 3, {
				type: VPERIOD,
				accounts: [ZERO_ADDRESS],
				amounts: [100],
				payloads: [0x00]
			})
			expect(result.didProposalPass).equal(true)
			expect(await forum.votingPeriod()).equal(100)
		})
		it('should count votes correctly for simple majority vote', async function () {
			let result

			// Pass a prop to change TYPE votes to require simple majority for this test
			result = await processProposal(forum, [receiver, sender], 2, {
				type: TYPE,
				accounts: [ZERO_ADDRESS, ZERO_ADDRESS],
				amounts: [TYPE, SIMPLE_MAJORITY],
				payloads: [0x00, 0x00]
			})
			expect(await forum.proposalVoteTypes(TYPE)).equal(SIMPLE_MAJORITY)

			// This tests a simple majority vote
			// Should not pass as it did not get enough votes
			result = await processProposal(forum, [sender], 3, {
				type: VPERIOD,
				accounts: [ZERO_ADDRESS],
				amounts: [100],
				payloads: [0x00]
			})
			expect(result.didProposalPass).equal(false)

			// Should pass as this time it has enough votes
			result = await processProposal(forum, [receiver, sender], 4, {
				type: VPERIOD,
				accounts: [ZERO_ADDRESS],
				amounts: [100],
				payloads: [0x00]
			})
			expect(result.didProposalPass).equal(true)
			expect(await forum.votingPeriod()).equal(100)
		})
		it('should count votes correctly for tokenVoteThreshold vote', async function () {
			let result

			// Pass a prop to change TYPE votes to require super majority for this test
			result = await processProposal(forum, [receiver, sender], 2, {
				type: TYPE,
				accounts: [ZERO_ADDRESS, ZERO_ADDRESS],
				amounts: [TYPE, TOKEN_MAJORITY],
				payloads: [0x00, 0x00]
			})
			expect(await forum.proposalVoteTypes(TYPE)).equal(TOKEN_MAJORITY)

			// This tests a super majority vote
			// Should not pass as it did not get enough votes
			result = await processProposal(forum, [sender], 3, {
				type: VPERIOD,
				accounts: [ZERO_ADDRESS],
				amounts: [100],
				payloads: [0x00]
			})
			expect(result.didProposalPass).equal(false)

			// Should pass as this time it has enough votes
			result = await processProposal(forum, [receiver, sender], 4, {
				type: VPERIOD,
				accounts: [ZERO_ADDRESS],
				amounts: [100],
				payloads: [0x00]
			})
			expect(result.didProposalPass).equal(true)
			expect(await forum.votingPeriod()).equal(100)
		})
		it('should check delegates after a delegation', async function () {
			await forum.connect(sender).delegate(receiver.address)

			// Sender has delegated to receiver
			expect(await forum.memberDelegatee(sender.address)).equal(receiver.address)
			expect(await forum.delegators(sender.address)).deep.equal([])
			expect(await forum.memberDelegatee(receiver.address)).equal(ZERO_ADDRESS)
			expect(await forum.delegators(receiver.address)).deep.equal([sender.address])
		})
		it('should revert if member tries to delegate, while they are delegated to', async function () {
			await forum.connect(sender).delegate(receiver.address)

			await expect(forum.connect(receiver).delegate(sender.address)).revertedWith(
				'InvalidDelegate()'
			)
		})
		it('should allow a member to remove a delegator on themselves', async function () {
			await forum.connect(sender).delegate(receiver.address)

			// Sender has delegated to receiver
			expect(await forum.memberDelegatee(sender.address)).equal(receiver.address)
			expect(await forum.delegators(receiver.address)).deep.equal([sender.address])

			await forum.connect(receiver).removeDelegator(sender.address)

			// Receiver no longer has a delegator
			expect(await forum.memberDelegatee(sender.address)).equal(ZERO_ADDRESS)
			expect(await forum.delegators(receiver.address)).deep.equal([])
		})
		it('should allow member to remove their delegatee via `delegate` function', async function () {
			await forum.connect(sender).delegate(receiver.address)

			// Sender has delegated to receiver
			expect(await forum.memberDelegatee(sender.address)).equal(receiver.address)
			expect(await forum.delegators(receiver.address)).deep.equal([sender.address])

			// 'to' address can be anyone, the delegator will simple be reset to 0
			await forum.connect(sender).delegate(alice.address)

			// Sender has now changed delegates to alice
			expect(await forum.memberDelegatee(sender.address)).equal(ZERO_ADDRESS)
			expect(await forum.delegators(receiver.address)).deep.equal([])
		})
		it('should revert if attempt to remove invald delegator', async function () {
			await expect(forum.connect(receiver).removeDelegator(sender.address)).revertedWith(
				'InvalidDelegate()'
			)
		})
		it('should forbid delegation interactions from/to non member', async function () {
			await expect(forum.connect(bob).delegate(sender.address)).revertedWith(
				'InvalidDelegate()'
			)
			await expect(forum.connect(sender).delegate(bob.address)).revertedWith(
				'InvalidDelegate()'
			)
		})
		it('should forbid member from transferring membership if they have delegates or are delegated to', async function () {
			// Disable pause for this test
			await processProposal(forum, [proposer, sender], 2, {
				type: PAUSE,
				accounts: [ZERO_ADDRESS],
				amounts: [0],
				payloads: [0x00]
			})

			await forum.connect(sender).delegate(receiver.address)

			// Revert if member has delegated to someone
			await expect(
				forum
					.connect(sender)
					.safeTransferFrom(sender.address, receiver.address, MEMBERSHIP, 1, '0x00')
			).revertedWith('InvalidDelegate()')

			// Revert if member is delegated to
			await expect(
				forum
					.connect(receiver)
					.safeBatchTransferFrom(
						receiver.address,
						sender.address,
						[MEMBERSHIP],
						[1],
						'0x00'
					)
			).revertedWith('InvalidDelegate()')
		})
		it('should forbid member from leaving if they have delegates or are delegated to', async function () {
			await forum.connect(sender).delegate(receiver.address)

			// Revert if member has delegated to someone
			await expect(
				processProposal(forum, [receiver], 2, {
					type: BURN,
					accounts: [sender.address],
					amounts: [0],
					payloads: [0x00]
				})
			).revertedWith('InvalidDelegate()')

			// Revert if member is delegated to
			await expect(
				processProposal(forum, [receiver], 3, {
					type: BURN,
					accounts: [receiver.address],
					amounts: [0],
					payloads: [0x00]
				})
			).revertedWith('InvalidDelegate()')
		})
		it('should allow delegation by sig and revert if sig incorrect', async function () {
			const sig1 = await createSignature(1, forum, sender, {
				delegatee: receiver.address,
				nonce: 0
			})

			await forum.delegateBySig(receiver.address, 0, 1941543121, sig1.v, sig1.r, sig1.s)

			// Sender has delegated to receiver
			expect(await forum.memberDelegatee(sender.address)).equal(receiver.address)
			expect(await forum.delegators(sender.address)).deep.equal([])
			expect(await forum.memberDelegatee(receiver.address)).equal(ZERO_ADDRESS)
			expect(await forum.delegators(receiver.address)).deep.equal([sender.address])

			const sig2 = await createSignature(1, forum, sender, {
				delegatee: receiver.address,
				nonce: 1
			})

			await expect(
				forum.delegateBySig(receiver.address, 0, 1941543121, sig2.v, sig2.r, sig2.s)
			).revertedWith('InvalidDelegate()')
		})
		it('should count all delegated votes and pass proposal for each vote type', async function () {
			// Receiver should now have their + sender's votes
			await forum.connect(sender).delegate(receiver.address)

			expect(await forum.proposalVoteTypes(TYPE)).equal(MEMBER)

			// This tests a member vote
			// Pass a prop to change TYPE votes to require simple majority
			await processProposal(forum, [receiver], 2, {
				type: TYPE,
				accounts: [ZERO_ADDRESS, ZERO_ADDRESS],
				amounts: [TYPE, SIMPLE_MAJORITY],
				payloads: [0x00, 0x00]
			})
			// Receiver has senders delegation and the vote type has been updated to simple majority meaning member vote worked
			expect(await forum.delegators(receiver.address)).deep.equal([sender.address])
			expect(await forum.proposalVoteTypes(TYPE)).equal(SIMPLE_MAJORITY)

			// This tests a simple majority vote
			// Pass a prop to change TYPE votes to tokenVoteThreshold
			await processProposal(forum, [receiver], 3, {
				type: TYPE,
				accounts: [ZERO_ADDRESS, ZERO_ADDRESS],
				amounts: [TYPE, TOKEN_MAJORITY],
				payloads: [0x00, 0x00]
			})

			// Vote type has been updated to tokenVoteThreshold - meaning the simple majority vote worked
			expect(await forum.proposalVoteTypes(TYPE)).equal(TOKEN_MAJORITY)

			// This tests a tokenVoteThreshold vote
			// Pass a prop to change TYPE votes back to member vote
			await processProposal(forum, [receiver], 4, {
				type: TYPE,
				accounts: [ZERO_ADDRESS, ZERO_ADDRESS],
				amounts: [TYPE, MEMBER],
				payloads: [0x00, 0x00]
			})

			// Vote type has been updated back to member, meaning that tokenVoteThreshold vote worked
			expect(await forum.proposalVoteTypes(TYPE)).equal(MEMBER)
		})
		it('should not count votes if member has delegated', async function () {
			// Sender no longer has votes
			await forum.connect(sender).delegate(receiver.address)

			// Vote type is member
			expect(await forum.proposalVoteTypes(TYPE)).equal(MEMBER)

			// Pass a prop trying to chage type from member to simple majority
			// This will not pass as sender has weight=0, alice has weight=1, and 2 are required
			await processProposal(forum, [alice, sender], 2, {
				type: TYPE,
				accounts: [ZERO_ADDRESS, ZERO_ADDRESS],
				amounts: [TYPE, SIMPLE_MAJORITY],
				payloads: [0x00, 0x00]
			})

			// Vote type is still member, the vote did not work
			expect(await forum.proposalVoteTypes(TYPE)).equal(MEMBER)
		})
		it('should forbid calling a non-whitelisted extension', async function () {
			await expect(forum.callExtension(sender.address, 10, 0x0)).revertedWith(
				'NotExtension()'
			)
		})
		it('should forbid non-whitelisted extension calling DAO', async function () {
			await expect(
				forum.connect(alice).callExtension(nonextension.address, 10, 0x0)
			).revertedWith('NotExtension()')
		})
		it('should not call if null length payload', async () => {
			let CallMock // CallMock contract
			let callMock // CallMock contract instance

			CallMock = await hardhatEthers.getContractFactory('CallMock')
			callMock = await CallMock.deploy()
			await callMock.deployed()

			expect(await callMock.called()).equal(false)
		})
		it('create a contract (EIP-1271) signature for use by the group', async () => {
			const testData = ethers.utils.id('test')

			// This is an awkward way to sign, but for now works
			const pk = findPrivateKey(receiver.address)
			const signingKey = new ethers.utils.SigningKey(pk)

			const signature = signingKey.signDigest(testData)
			const fullSig = ethers.utils.joinSignature(signature)

			// Make prop to create a signature as validation for a given payload
			// accounts[0] is the account to be appproved to use the signature
			await processProposal(forum, [receiver, sender], 2, {
				type: ALLOW_CONTRACT_SIG,
				accounts: [sender.address],
				amounts: [getBigNumber(0)],
				payloads: [testData]
			})

			expect(await forum.connect(sender).isValidSignature(testData, fullSig)).equal(
				'0x1626ba7e'
			)
		})
		it('should revert is signature replayed', async function () {
			// Propose a simple VPeriod proposal
			forum.connect(proposer).propose(VPERIOD, [ZERO_ADDRESS], [100], [0x00])

			const proposerSig2 = await createSignature(0, forum, proposer, {
				proposal: 2
			})
			await forum.processProposal(2, [proposerSig2])

			// Propose another simple VPeriod proposal
			forum.connect(proposer).propose(VPERIOD, [ZERO_ADDRESS], [200], [0x00])
			await expect(forum.processProposal(3, [proposerSig2])).revertedWith('SignatureError()')
		})
		it('should revert reentrant calls', async () => {
			const ReentrantMock = await hardhatEthers.getContractFactory('ReentrantMock')
			const reentrantMock = await ReentrantMock.deploy()
			await reentrantMock.deployed()

			await processProposal(forum, [receiver, sender], 2, {
				type: EXTENSION,
				accounts: [reentrantMock.address],
				amounts: [1],
				payloads: [0x00]
			})

			expect(await forum.extensions(reentrantMock.address)).equal(true)
			await expect(forum.callExtension(reentrantMock.address, 0, '0x00')).revertedWith(
				'Reentrancy'
			)
		})
	})
})
