// import { expect } from '../utils/expect'
// import { advanceTime, getBigNumber } from '../utils/helpers'
// import { voteProposal } from '../utils/voteProposal'

// //import { toChecksumAddress } from '../../../ui/handlers/web3'
// import { Delegator, ForumGroup } from '../../typechain'
// import {
// 	DELEGATION,
// 	EXTENSION,
// 	GET_VOTE_BALANCE,
// 	MEMBERSHIP,
// 	MINT,
// 	PAUSE,
// 	TOKEN_THRESHOLD,
// 	TOKEN,
// 	TYPE,
// 	ZERO_ADDRESS
// } from '../config'

// import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
// import { deployments, ethers as hardhatEthers } from 'hardhat'
// import { beforeEach, describe, it } from 'mocha'

// // TODO create a delegator util to tidy code
// describe('Delegate Module', () => {
// 	let forum: ForumGroup // ForumGroup contract instance
// 	let delegatorExt: Delegator // ForumGroup contract instance
// 	let founder: any // signerA
// 	let extensionSimulator: any // signerB
// 	let alice: SignerWithAddress // signerB
// 	let bob: SignerWithAddress // signerB
// 	let carol: SignerWithAddress // signerB

// 	describe('Setup Extension and Reverted Setups', () => {
// 		beforeEach(async () => {
// 			;[founder, extensionSimulator, alice, bob, carol] = await hardhatEthers.getSigners()

// 			await deployments.fixture(['Forum'])
// 			forum = await hardhatEthers.getContract('ForumGroup')
// 			delegatorExt = await hardhatEthers.getContract('Delegator')

// 			await forum.deployed()
// 		})
// 		it('should enable delegator extension and check vote balances', async () => {
// 			// Init group
// 			await forum.init(
// 				'FORUM',
// 				'FORUM',
// 				[founder.address, alice.address],
// 				[ZERO_ADDRESS, ZERO_ADDRESS],
// 				[30, 0, 50, 60]
// 			)

// 			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
// 			await voteProposal(forum, founder, 1, {
// 				type: EXTENSION,
// 				accounts: [extensionSimulator.address],
// 				amounts: [1],
// 				payloads: [0x00]
// 			})

// 			// Mint founder and alice shares
// 			await forum.connect(extensionSimulator).mintShares(founder.address, TOKEN, getBigNumber(10))
// 			await forum.connect(extensionSimulator).mintShares(alice.address, TOKEN, getBigNumber(10))

// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address, alice.address]]
// 			)

// 			// Enable delegate extension for dao - now all votes are counted from delegator, minting or burning updates values on the delegator
// 			await voteProposal(forum, founder, 2, {
// 				type: DELEGATION,
// 				accounts: [delegatorExt.address],
// 				amounts: [1],
// 				payloads: [payload]
// 			})

// 			// Below we check the balances of both members are what they minted earlier, and their votes on the delegator match that
// 			expect(await forum.balanceOf(founder.address, TOKEN)).equal(getBigNumber(10))
// 			expect(await forum.balanceOf(alice.address, TOKEN)).equal(getBigNumber(10))
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).equal(
// 				await forum.balanceOf(founder.address, TOKEN)
// 			)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).equal(
// 				await forum.balanceOf(founder.address, TOKEN)
// 			)
// 		})
// 		it('reverts setting if a non-member is included in array', async () => {
// 			// Init group
// 			await forum.init(
// 				'FORUM',
// 				'FORUM',
// 				[founder.address, alice.address],
// 				[ZERO_ADDRESS, ZERO_ADDRESS],
// 				[30, 0, 50, 60]
// 			)

// 			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
// 			await voteProposal(forum, founder, 1, {
// 				type: EXTENSION,
// 				accounts: [extensionSimulator.address],
// 				amounts: [1],
// 				payloads: [0x00]
// 			})

// 			// Mint founder and alice shares
// 			await forum.connect(extensionSimulator).mintShares(founder.address, TOKEN, getBigNumber(10))
// 			await forum.connect(extensionSimulator).mintShares(alice.address, TOKEN, getBigNumber(10))

// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address, extensionSimulator.address]]
// 			)

// 			await forum.connect(founder).propose(DELEGATION, [delegatorExt.address], [1], [payload])
// 			await forum.connect(founder).vote(2)
// 			await advanceTime(35)

// 			// TODO correct check of this revert - hardhat errors but gives no reason
// 			//await expect(forum.processProposal(2)).reverted()
// 			// expect(await forum.extensions(delegatorExt.address)).equal(true) ???
// 		})
// 		it('reverts setting if not all members are included (accounts for new member joining after delegation set)', async () => {
// 			// Init group
// 			await forum.init(
// 				'FORUM',
// 				'FORUM',
// 				[founder.address, alice.address],
// 				[ZERO_ADDRESS, ZERO_ADDRESS],
// 				[30, 0, 50, 60]
// 			)

// 			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
// 			await voteProposal(forum, founder, 1, {
// 				type: EXTENSION,
// 				accounts: [extensionSimulator.address],
// 				amounts: [1],
// 				payloads: [0x00]
// 			})

// 			// Mint founder and alice shares
// 			await forum.connect(extensionSimulator).mintShares(founder.address, TOKEN, getBigNumber(10))
// 			await forum.connect(extensionSimulator).mintShares(alice.address, TOKEN, getBigNumber(10))

// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address]]
// 			)

// 			await forum.connect(founder).propose(DELEGATION, [delegatorExt.address], [1], [payload])
// 			await forum.connect(founder).vote(2)
// 			await advanceTime(35)
// 			//await expect(forum.processProposal(2)).revertedWith('MembersMissing()')
// 		})
// 		it('reverts if msg.sender !=dao', async () => {
// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address, alice.address]]
// 			)

// 			await expect(delegatorExt.connect(alice).setExtension(payload)).revertedWith('Forbidden()')
// 		})
// 		it('should turn off delegation for a multisig', async () => {
// 			// Init group
// 			await forum.init(
// 				'FORUM',
// 				'FORUM',
// 				[founder.address, alice.address],
// 				[ZERO_ADDRESS, ZERO_ADDRESS],
// 				[30, 0, 50, 60]
// 			)

// 			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
// 			await voteProposal(forum, founder, 1, {
// 				type: EXTENSION,
// 				accounts: [extensionSimulator.address],
// 				amounts: [1],
// 				payloads: [0x00]
// 			})

// 			// Mint founder and alice shares
// 			await forum.connect(extensionSimulator).mintShares(founder.address, TOKEN, getBigNumber(10))
// 			await forum.connect(extensionSimulator).mintShares(alice.address, TOKEN, getBigNumber(10))

// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address, alice.address]]
// 			)

// 			// Enable delegate extension for dao - now all votes are counted from delegator, minting or burning updates values on the delegator
// 			await voteProposal(forum, founder, 2, {
// 				type: DELEGATION,
// 				accounts: [delegatorExt.address],
// 				amounts: [0],
// 				payloads: [payload]
// 			})

// 			// After setting the extension, each member has 1 checkpoint
// 			expect(await delegatorExt.numCheckpoints(forum.address, founder.address)).equal(1)
// 			expect(await delegatorExt.numCheckpoints(forum.address, alice.address)).equal(1)

// 			// Turn off delegation extension
// 			await voteProposal(forum, founder, 3, {
// 				type: DELEGATION,
// 				accounts: [delegatorExt.address],
// 				amounts: [0],
// 				payloads: [payload]
// 			})

// 			// Memebrs have anther checkpoint, most recent checkpoints are all set to 0
// 			expect(await delegatorExt.numCheckpoints(forum.address, founder.address)).equal(2)
// 			expect(await delegatorExt.numCheckpoints(forum.address, alice.address)).equal(2)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).equal(0)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).equal(0)
// 		})
// 		it('reverts turning off delegation for a multisig with open proposals', async () => {
// 			// Init group
// 			await forum.init(
// 				'FORUM',
// 				'FORUM',
// 				[founder.address, alice.address],
// 				[ZERO_ADDRESS, ZERO_ADDRESS],
// 				[30, 0, 50, 60]
// 			)

// 			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
// 			await voteProposal(forum, founder, 1, {
// 				type: EXTENSION,
// 				accounts: [extensionSimulator.address],
// 				amounts: [1],
// 				payloads: [0x00]
// 			})

// 			// Mint founder and alice shares
// 			await forum.connect(extensionSimulator).mintShares(founder.address, TOKEN, getBigNumber(10))
// 			await forum.connect(extensionSimulator).mintShares(alice.address, TOKEN, getBigNumber(10))

// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address, alice.address]]
// 			)

// 			// Enable delegate extension for dao - now all votes are counted from delegator, minting or burning updates values on the delegator
// 			await voteProposal(forum, founder, 2, {
// 				type: DELEGATION,
// 				accounts: [delegatorExt.address],
// 				amounts: [0],
// 				payloads: [payload]
// 			})

// 			// Make any proposal
// 			await forum.connect(founder).propose(MINT, [bob.address], [0], ['0x00'])

// 			// Make a proposal to turn off delegatation, which will be reverted
// 			await expect(
// 				voteProposal(forum, founder, 4, {
// 					type: DELEGATION,
// 					accounts: [delegatorExt.address],
// 					amounts: [0],
// 					payloads: [payload]
// 				})
// 			).revertedWith('NotCurrentProposal()')

// 			// Vote blanaces still on delegator
// 			expect(await forum.extensions(delegatorExt.address)).not.equal(ZERO_ADDRESS)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).equal(
// 				await forum.balanceOf(founder.address, 1)
// 			)
// 		})
// 	})

// 	describe('Calling Extension', () => {
// 		beforeEach(async () => {
// 			;[founder, extensionSimulator, alice, bob, carol] = await hardhatEthers.getSigners()

// 			await deployments.fixture(['Forum'])
// 			forum = await hardhatEthers.getContract('ForumGroup')
// 			delegatorExt = await hardhatEthers.getContract('Delegator')

// 			await forum.deployed()

// 			// Init group
// 			await forum.init(
// 				'FORUM',
// 				'FORUM',
// 				[founder.address, alice.address],
// 				[ZERO_ADDRESS, ZERO_ADDRESS],
// 				[30, 0, 50, 60]
// 			)

// 			// TESTING - set an address to act as an extension, this allows us to mint shares. In prod this will be a real extension contract
// 			await voteProposal(forum, founder, 1, {
// 				type: EXTENSION,
// 				accounts: [extensionSimulator.address],
// 				amounts: [1],
// 				payloads: [0x00]
// 			})

// 			// Mint founder and alice shares
// 			await forum.connect(extensionSimulator).mintShares(founder.address, TOKEN, getBigNumber(10))
// 			await forum.connect(extensionSimulator).mintShares(alice.address, TOKEN, getBigNumber(10))

// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address, alice.address]]
// 			)

// 			// Enable delegate extension for dao - now all votes are counted from delegator, minting or burning updates values on the delegator
// 			await voteProposal(forum, founder, 2, {
// 				type: DELEGATION,
// 				accounts: [delegatorExt.address],
// 				amounts: [1],
// 				payloads: [payload]
// 			})
// 		})
// 		// Calling Extension
// 		it('Should return the delegated balance by calling callExtension on Delegator (call type 0)', async () => {
// 			// Get timestamp on checkpoint - for testing only, the real timestamp will come from a proposal
// 			const cp = (await delegatorExt.checkpoints(forum.address, founder.address, 0)).fromTimestamp

// 			// Call extension proposal - type 0 (get vote balance)
// 			const payloadCall = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address', 'address', 'uint256', 'uint256'],
// 				[
// 					forum.address,
// 					founder.address,
// 					'0x0000000000000000000000000000000000000000',
// 					cp,
// 					GET_VOTE_BALANCE
// 				]
// 			)

// 			const tx = await (await delegatorExt.callExtension(founder.address, 1, payloadCall)).wait()
// 			const amountOfVotes = tx.events[0].args?.amount

// 			expect(amountOfVotes).equal(getBigNumber(10))
// 		})
// 		it('Should update the vote balances in the delegator after minting more shares (call type 1)', async () => {
// 			// Check balances  are equal to checkpoints
// 			expect((await delegatorExt.checkpoints(forum.address, founder.address, 0)).votes).equal(
// 				await forum.balanceOf(founder.address, TOKEN)
// 			)
// 			expect((await delegatorExt.checkpoints(forum.address, alice.address, 0)).votes).equal(
// 				await forum.balanceOf(alice.address, TOKEN)
// 			)

// 			// mint 10 more shares to the founder [internally calls extension with call type 1]
// 			await forum.connect(extensionSimulator).mintShares(founder.address, TOKEN, getBigNumber(10))

// 			// Get timestamp on checkpoint - for testing only, the real timestamp will come from a proposal
// 			const cp = (await delegatorExt.checkpoints(forum.address, founder.address, 1)).fromTimestamp

// 			// Call extension proposal - type 0 (get vote balance)
// 			const payloadCall = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address', 'address', 'uint256', 'uint256'],
// 				[
// 					forum.address,
// 					founder.address,
// 					'0x0000000000000000000000000000000000000000',
// 					cp,
// 					GET_VOTE_BALANCE
// 				]
// 			)

// 			const tx = await (await delegatorExt.callExtension(founder.address, 1, payloadCall)).wait()
// 			const amountOfVotes = tx.events[0].args?.amount

// 			expect(amountOfVotes).equal(getBigNumber(20))
// 			expect((await delegatorExt.checkpoints(forum.address, founder.address, 1)).votes).equal(
// 				await forum.balanceOf(founder.address, TOKEN)
// 			)
// 		})
// 		it("Should list member as 'delegate' if no delegation to others", async function () {
// 			expect(await delegatorExt.delegates(forum.address, founder.address)).to.equal(founder.address)
// 		})
// 		it('Should allow vote delegation', async function () {
// 			await delegatorExt.delegate(forum.address, alice.address)

// 			expect(await delegatorExt.delegates(forum.address, founder.address)).to.equal(alice.address)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(0)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).to.equal(
// 				getBigNumber(20)
// 			)
// 			expect(await forum.balanceOf(founder.address, TOKEN)).to.equal(getBigNumber(10))
// 			expect(await forum.balanceOf(alice.address, TOKEN)).to.equal(getBigNumber(10))

// 			await delegatorExt.delegate(forum.address, founder.address)
// 			expect(await delegatorExt.delegates(forum.address, founder.address)).to.equal(founder.address)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(
// 				getBigNumber(10)
// 			)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).to.equal(
// 				getBigNumber(10)
// 			)
// 		})
// 		it('Should update votes on a transfer of tokens', async () => {
// 			await voteProposal(forum, founder, 3, {
// 				type: PAUSE,
// 				accounts: [],
// 				amounts: [],
// 				payloads: []
// 			})
// 			// Add a new member to test transfer with
// 			await voteProposal(forum, founder, 4, {
// 				type: MINT,
// 				accounts: [bob.address],
// 				amounts: [0],
// 				payloads: ['0x00']
// 			})

// 			await delegatorExt.delegate(forum.address, alice.address)
// 			await advanceTime(35)

// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(0)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).to.equal(
// 				getBigNumber(20)
// 			)

// 			await forum.safeTransferFrom(founder.address, bob.address, TOKEN, getBigNumber(5), '0x00')
// 			await advanceTime(35)

// 			expect(await delegatorExt.getCurrentVotes(forum.address, bob.address)).to.equal(
// 				getBigNumber(5)
// 			)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(0)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).to.equal(
// 				getBigNumber(15)
// 			)
// 			await delegatorExt.delegate(forum.address, founder.address)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(
// 				getBigNumber(5)
// 			)
// 		})
// 		it('Should update votes on a batch transfer of tokens', async () => {
// 			await voteProposal(forum, founder, 3, {
// 				type: PAUSE,
// 				accounts: [],
// 				amounts: [],
// 				payloads: []
// 			})
// 			// Add a new member to test transfer with
// 			await voteProposal(forum, founder, 4, {
// 				type: MINT,
// 				accounts: [bob.address],
// 				amounts: [0],
// 				payloads: ['0x00']
// 			})

// 			await delegatorExt.delegate(forum.address, alice.address)
// 			await advanceTime(35)

// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(0)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).to.equal(
// 				getBigNumber(20)
// 			)

// 			await forum.safeBatchTransferFrom(
// 				founder.address,
// 				bob.address,
// 				[TOKEN],
// 				[getBigNumber(5)],
// 				'0x00'
// 			)
// 			await advanceTime(35)

// 			expect(await delegatorExt.getCurrentVotes(forum.address, bob.address)).to.equal(
// 				getBigNumber(5)
// 			)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(0)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).to.equal(
// 				getBigNumber(15)
// 			)
// 			await delegatorExt.delegate(forum.address, founder.address)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(
// 				getBigNumber(5)
// 			)
// 		})
// 		it('reverts if transferred to non group member', async () => {
// 			// Set up payload for extension proposal
// 			const payload = hardhatEthers.utils.defaultAbiCoder.encode(
// 				['address', 'address[]'],
// 				[forum.address, [founder.address, alice.address]]
// 			)
// 			await expect(
// 				forum
// 					.connect(founder)
// 					.safeTransferFrom(founder.address, bob.address, TOKEN, getBigNumber(10), '0x00')
// 			).revertedWith('Paused()')
// 		})
// 		it('processes a vote based on delegated votes', async () => {
// 			// Proposal to change the type of MINT votes to be tokenVoteThreshold (2)
// 			await voteProposal(forum, founder, 3, {
// 				type: TYPE,
// 				accounts: [ZERO_ADDRESS, ZERO_ADDRESS],
// 				amounts: [MINT, 2],
// 				payloads: ['0x00', '0x00']
// 			})

// 			// Set tokenVoteThreshold threshold for vote type to 100%
// 			await voteProposal(forum, founder, 4, {
// 				type: TOKEN_THRESHOLD,
// 				accounts: [ZERO_ADDRESS],
// 				amounts: [100],
// 				payloads: ['0x00']
// 			})

// 			// Vote fails when voted for my alice
// 			await expect(
// 				voteProposal(forum, alice, 5, {
// 					type: MINT,
// 					accounts: [bob.address],
// 					amounts: [0],
// 					payloads: ['0x00']
// 				})
// 			).revertedWith('NotVoteable()')

// 			// Delegate votes to alice, she now has 100% votes
// 			await delegatorExt.delegate(forum.address, alice.address)
// 			await advanceTime(35)

// 			// The vote passes just from alice's delegated votes
// 			await voteProposal(forum, alice, 6, {
// 				type: MINT,
// 				accounts: [bob.address],
// 				amounts: [0],
// 				payloads: ['0x00']
// 			})

// 			expect(await forum.balanceOf(bob.address, MEMBERSHIP)).to.equal(1)
// 		})
// 		it('Should allow delegateBySig if the signature is valid', async () => {
// 			const domain = {
// 				name: 'Delegator',
// 				version: '1',
// 				chainId: 43114,
// 				verifyingContract: delegatorExt.address
// 			}
// 			const types = {
// 				Delegation: [
// 					{ name: 'dao', type: 'address' },
// 					{ name: 'delegator', type: 'address' },
// 					{ name: 'delegatee', type: 'address' },
// 					{ name: 'nonce', type: 'uint256' },
// 					{ name: 'deadline', type: 'uint256' }
// 				]
// 			}
// 			const value = {
// 				dao: forum.address,
// 				delegator: founder.address,
// 				delegatee: alice.address,
// 				nonce: 0,
// 				deadline: 1941543121
// 			}

// 			const signature = await founder._signTypedData(domain, types, value)
// 			const { r, s, v } = hardhatEthers.utils.splitSignature(signature)

// 			await delegatorExt
// 				.connect(alice)
// 				.delegateBySig(forum.address, founder.address, alice.address, 0, 1941543121, v, r, s)

// 			expect(await delegatorExt.getCurrentVotes(forum.address, alice.address)).to.equal(
// 				getBigNumber(20)
// 			)
// 			expect(await delegatorExt.getCurrentVotes(forum.address, founder.address)).to.equal(0)
// 		})
// 		it('Should revert delegateBySig if the signature is invalid', async () => {
// 			const rs = hardhatEthers.utils.formatBytes32String('rs')
// 			expect(
// 				await delegatorExt.delegateBySig(
// 					forum.address,
// 					founder.address,
// 					alice.address,
// 					0,
// 					1941525801,
// 					0,
// 					rs,
// 					rs
// 				).should.be.reverted
// 			)
// 		})
// 	})
// })
