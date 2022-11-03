// import { expect } from '../utils/expect'
// import { getBigNumber, parseEther } from '../utils/helpers'
// import snapshotGasCost from '../utils/snapshotGasCost'

// import { AccessManager } from '../../typechain'
// import {
// 	BASIC_ACCESS,
// 	BASIC_ACCESS_ITEM,
// 	BASIC_FEATURE_ITEM,
// 	BASIC_ITEM,
// 	BRONZE_ACCESS,
// 	BRONZE_ACCESS_ITEM,
// 	BRONZE_DISCOUNT,
// 	BRONZE_SVG,
// 	EXPECTED_BASIC_PASS,
// 	EXPECTED_BRONZE_PASS,
// 	GOLD_ACCESS,
// 	GOLD_ACCESS_ITEM,
// 	GOLD_DISCOUNT,
// 	GOLD_ITEM,
// 	NO_ACCESS,
// 	SILVER_ACCESS,
// 	SILVER_ACCESS_ITEM,
// 	SILVER_DISCOUNT,
// 	SILVER_ITEM,
// 	SILVER_SVG,
// 	SPECIAL_FEATURE_GOLD_ITEM,
// 	SPECIAL_FEATURE_SILVER_ITEM
// } from '../config'

// import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
// import { BigNumber, Contract, Signer } from 'ethers'
// import { deployments, ethers, ethers as hardhatEthers } from 'hardhat'
// import { beforeEach, describe, it } from 'mocha'

// import chai = require('chai')

// chai.should()

// describe('Access Manager', function () {
// 	let owner: SignerWithAddress
// 	let wallet: SignerWithAddress
// 	let alice: SignerWithAddress
// 	let bob: SignerWithAddress
// 	let charlie: SignerWithAddress
// 	let accessManager: AccessManager

// 	beforeEach(async () => {
// 		;[owner, wallet, alice, bob, charlie] = await hardhatEthers.getSigners()

// 		await deployments.fixture(['Forum'])
// 		// accessManager = await ethers.getContract('AccessPassStore')
// 		accessManager = await ethers.getContract('AccessManager')

// 		// await deployments.fixture(['Forum'])

// 	})

// 	describe('Constructor & Setup', () => {
// 		// test unavailable as the AccessManager is already configured in the fixtures above
// 		// it('deployment gas', async () => {
// 		// 	await snapshotGasCost(
// 		// 		await (
// 		// 			await hardhatEthers.getContractFactory('AccessManager')
// 		// 		).deploy('AM', 'AM', accessManager.address)
// 		// 	)
// 		// })
// 		it('has bytecode size', async () => {
// 			expect(
// 				((await accessManager.provider.getCode(accessManager.address)).length - 2) / 2
// 			).matchSnapshot()
// 		})
// 		it('initializes', async () => {
// 			expect(await accessManager.name()).equal('ACCESS_MANAGER')
// 			expect(await accessManager.symbol()).equal('AM')
// 		})
// 	})

// 	describe('Manage Items', () => {
// 		it('checks the details of the (basic access) item added in the constructor', async () => {
// 			expect((await accessManager.itemDetails(BASIC_ACCESS)).price).equal(BASIC_ACCESS_ITEM.price)
// 			// Checks pass uri against pre calcualted result
// 			expect(await accessManager.uri(BASIC_ACCESS)).equal(EXPECTED_BASIC_PASS)
// 		})
// 		it('adds an item', async () => {
// 			// Checks item description before and after adding
// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).price).equal(0)

// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)
// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).price).equal(BRONZE_ACCESS_ITEM.price)
// 			// Checks pass details in AccessPassStore against pre calcualted result
// 			expect(await accessManager.uri(BRONZE_ACCESS)).equal(BRONZE_ACCESS)
// 		})
// 		it('prevents non owner from adding an item', async () => {
// 			await expect(
// 				accessManager
// 					.connect(alice)
// 					.addItem(
// 						getBigNumber(BRONZE_ACCESS_ITEM.price),
// 						BRONZE_ACCESS_ITEM.maxSupply,
// 						BRONZE_ACCESS_ITEM.accessLevel,
// 						BRONZE_ACCESS_ITEM.resaleRoyalty
// 					)
// 			).revertedWith('NotOwner()')
// 		})
// 		it('updates the availability of an item', async () => {
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)

// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).live).equal(false)
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).live).equal(true)
// 		})
// 		it('prevents non owner updating the availability of an item', async () => {
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await expect(accessManager.connect(alice).setItemMintLive(BRONZE_ACCESS, true)).revertedWith(
// 				'NotOwner()'
// 			)
// 		})
// 	})

// 	describe('Manage Whitelist', () => {
// 		let domain
// 		let types

// 		beforeEach(async () => {
// 			// domain = {
// 			// 	name: 'ROUNDTABLE_RELAY',
// 			// 	version: '1',
// 			// 	chainId: 43114,
// 			// 	verifyingContract: relay.address
// 			// }
// 			// types = {
// 			// 	ClaimWhitelist: [
// 			// 		{ name: 'claimer', type: 'address' },
// 			// 		{ name: 'item', type: 'uint256' },
// 			// 		{ name: 'counter', type: 'uint256' }
// 			// 	]
// 			// }

// 			// Set addresses and add pass to store
// 			await accessManager.connect(owner).setForumRelay(relay.address)
// 			await relay
// 				.connect(owner)
// 				.setAccessAndFactory(accessManager.address, '0x0000000000000000000000000000000000000000')

// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)
// 		})
// 		it('allows user to claim whitelist via relay', async () => {
// 			;[owner, wallet, alice, bob, charlie] = await hardhatEthers.getSigners()

// 			await relay.connect(wallet).forwardClaimWhitelistTx(alice.address, BASIC_ACCESS)

// 			expect(await accessManager.forumWhitelist(alice.address, BASIC_ACCESS)).equal(true)
// 		})
// 		// it('allows user to claim whitelist via relay', async () => {
// 		// 	;[owner, wallet, alice, bob, charlie] = await hardhatEthers.getSigners()

// 		// 	// Below would be generated on frontend, user would unlock feature by using coupon code
// 		// 	const value = {
// 		// 		claimer: alice.address,
// 		// 		item: 0,
// 		// 		counter: 0
// 		// 	}

// 		// 	// Simulate forum signing a message permitting a user to claim whitelist for an item
// 		// 	const signature = await wallet._signTypedData(domain, types, value)
// 		// 	const { r, s, v } = ethers.utils.splitSignature(signature)

// 		// 	await relay.connect(wallet).forwardTx(alice.address, 0, 0, r, s, v)

// 		// 	expect(await accessManager.forumWhitelist(alice.address, NO_ACCESS)).equal(true)
// 		// 	expect(
// 		// 		await relay.usedCodes('0x6dc2d82b050fadf8455daca298b84a0c537a15af1508a6bc7fb60aeb4094f370')
// 		// 	).equal(true)
// 		// })
// 		// TODO - consider tests which fail / prevent user from minting
// 		//			- since the message is signed by us, I'm not sure there are any cases to test (at least on contract side)

// 		it('adds address to whitelist for BRONZE_ACCESS', async () => {
// 			await accessManager.connect(owner).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 			expect(await accessManager.forumWhitelist(alice.address, BRONZE_ACCESS)).equal(true)
// 		})
// 		it('prevents non owner from adding to whitelist', async () => {
// 			await expect(
// 				accessManager.connect(alice).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 			).revertedWith('Unauthorised()')
// 		})
// 		it('removes address from whitelist', async () => {
// 			await accessManager.connect(owner).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 			await accessManager.connect(owner).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 			expect(await accessManager.forumWhitelist(alice.address, BRONZE_ACCESS)).equal(false)
// 		})
// 		it('prevents non owner from removing off whitelist', async () => {
// 			await accessManager.connect(owner).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 			await expect(
// 				accessManager.connect(alice).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 			).revertedWith('Unauthorised()')
// 		})
// 		it('prevents non owner batch minting and dropping items', async () => {
// 			await expect(
// 				accessManager
// 					.connect(alice)
// 					.mintAndDrop([BASIC_ACCESS], [3], [alice.address, bob.address, charlie.address])
// 			).revertedWith('NotOwner()')
// 		})
// 		it('prevents batch minting and dropping non existing items', async () => {
// 			await expect(
// 				accessManager
// 					.connect(owner)
// 					.mintAndDrop([10], [3], [alice.address, bob.address, charlie.address])
// 			).revertedWith('InvalidItem()')
// 		})
// 		it('prevents non owner batch minting and dropping items that arent live', async () => {
// 			await expect(
// 				accessManager
// 					.connect(owner)
// 					.mintAndDrop([BRONZE_ACCESS], [3], [alice.address, bob.address, charlie.address])
// 			).revertedWith('ItemUnavailable()')
// 		})
// 		it('prevents non owner batch minting and dropping items that would go over max supply', async () => {
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)

// 			await expect(
// 				accessManager
// 					.connect(owner)
// 					.mintAndDrop([BRONZE_ACCESS], [3], [alice.address, bob.address, charlie.address])
// 			).revertedWith('ItemUnavailable()')
// 		})
// 		it('batch mints items and transfers to users', async () => {
// 			const [owner, wallet, alice, bob, carol, d, e, f, g, h, i, j, k, l, m, n, o] =
// 				await hardhatEthers.getSigners()

// 			await accessManager
// 				.connect(owner)
// 				.mintAndDrop(
// 					[BASIC_ACCESS],
// 					[15],
// 					[
// 						alice.address,
// 						bob.address,
// 						carol.address,
// 						d.address,
// 						e.address,
// 						f.address,
// 						g.address,
// 						h.address,
// 						i.address,
// 						j.address,
// 						k.address,
// 						l.address,
// 						m.address,
// 						n.address,
// 						o.address
// 					]
// 				)
// 			expect(await accessManager.balanceOf(alice.address, BASIC_ACCESS)).equal(1)
// 			expect(await accessManager.balanceOf(bob.address, BASIC_ACCESS)).equal(1)
// 			expect(await accessManager.balanceOf(charlie.address, BASIC_ACCESS)).equal(1)
// 		})
// 		it('batch mints items and transfers to users - only if they dont have a pass', async () => {
// 			await accessManager.mintItem(BASIC_ACCESS, alice.address, { value: getBigNumber(0) })
// 			await accessManager
// 				.connect(owner)
// 				.mintAndDrop([BASIC_ACCESS], [3], [alice.address, bob.address, charlie.address])

// 			// alice should only have 1, even tho she had from before
// 			expect(await accessManager.balanceOf(alice.address, BASIC_ACCESS)).equal(1)
// 			expect(await accessManager.balanceOf(owner.address, BASIC_ACCESS)).equal(1)
// 			expect(await accessManager.balanceOf(bob.address, BASIC_ACCESS)).equal(1)
// 			expect(await accessManager.balanceOf(charlie.address, BASIC_ACCESS)).equal(1)
// 		})
// 	})

// 	describe('Mint Access Levels', () => {
// 		beforeEach(async () => {
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BASIC_ACCESS_ITEM.price),
// 					BASIC_ACCESS_ITEM.maxSupply,
// 					BASIC_ACCESS_ITEM.accessLevel,
// 					BASIC_ACCESS_ITEM.resaleRoyalty
// 				)

// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)

// 			await accessManager.connect(owner).addItem(
// 				getBigNumber(SILVER_ACCESS_ITEM.price),
// 				2, // manually set for simple tests below
// 				SILVER_ACCESS_ITEM.accessLevel,
// 				SILVER_ACCESS_ITEM.resaleRoyalty
// 			)
// 		})
// 		// The below test also covers attempts to mint an item before it exists
// 		it('Denies a user minting BRONZE_ACCESS before it is live', async () => {
// 			await expect(
// 				accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(0) })
// 			).revertedWith('MintingClosed()')
// 		})
// 		it('Denies a user minting BRONZE_ACCESS for insufficent funds', async () => {
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)

// 			await expect(
// 				accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(0) })
// 			).revertedWith('IncorrectValue()')
// 		})
// 		it('Lets user mint BRONZE_ACCESS, then checks supply of BRONZE_ACCESS', async () => {
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(1) })

// 			expect(await accessManager.balanceOf(alice.address, BRONZE_ACCESS)).equal(1)
// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).currentSupply).equal(1)
// 		})
// 		// it('mints BRONZE_ACCESS for whitelist user on that item, checks memberLevel', async () => {
// 		// 	await accessManager.connect(owner).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 		// 	await accessManager.connect(alice).whitelistMintItem(BRONZE_ACCESS)
// 		// 	expect(await accessManager.memberLevel(alice.address)).equal(BRONZE_ACCESS)

// 		// 	// Also check overall count of bronze token
// 		// 	expect((await accessManager.itemDetails(BRONZE_ACCESS)).currentSupply).equal(1)
// 		// })
// 		// The test below works for any level / item pass
// 		it('prevents user from minting multiple basic passes', async () => {
// 			await accessManager.setItemMintLive(BASIC_ACCESS, true)

// 			await accessManager.mintItem(BASIC_ACCESS, alice.address)
// 			await expect(accessManager.mintItem(BASIC_ACCESS, alice.address)).revertedWith(
// 				'AlreadyOwner()'
// 			)
// 		})
// 		// Dont really care about below case, its not bad since the user can only hold at most 1 of each level.
// 		// Benificial in case a user wants to sell their pass, but ensure they have a lower level secured.
// 		// it('prevents user from minting any lower level pass', async () => {
// 		// 	await accessManager.setItemMintLive(1, true)
// 		// 	await accessManager.setItemMintLive(2, true)
// 		// 	await accessManager.mintItem(SILVER_ACCESS, alice.address, { value: getBigNumber(2) })
// 		// 	await expect(accessManager.mintItem(BRONZE_ACCESS, alice.address)).revertedWith(
// 		// 		'InvalidItem()'
// 		// 	)
// 		// })
// 		it('prevents minting of level that has sold out', async () => {
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(1) })
// 			await expect(
// 				accessManager.mintItem(BRONZE_ACCESS, bob.address, { value: getBigNumber(1) })
// 			).revertedWith('ItemUnavailable()')
// 		})
// 		// it('prevents user from whitelist minting multiple silver passes', async () => {
// 		// 	await accessManager.connect(owner).toggleItemWhitelist(alice.address, SILVER_ACCESS)
// 		// 	await accessManager.connect(alice).whitelistMintItem(SILVER_ACCESS)

// 		// 	// Need to reset whitelist to test this since status is toggled after item is redeemed
// 		// 	await accessManager.connect(owner).toggleItemWhitelist(alice.address, SILVER_ACCESS)
// 		// 	await expect(accessManager.connect(alice).whitelistMintItem(SILVER_ACCESS)).revertedWith(
// 		// 		'AlreadyOwner()'
// 		// 	)
// 		// })
// 		// it('prevents whitelist minting of level that has sold out', async () => {
// 		// 	await accessManager.connect(owner).toggleItemWhitelist(alice.address, BRONZE_ACCESS)
// 		// 	await accessManager.connect(owner).toggleItemWhitelist(bob.address, BRONZE_ACCESS)

// 		// 	await accessManager.connect(alice).whitelistMintItem(BRONZE_ACCESS)
// 		// 	await expect(accessManager.connect(bob).whitelistMintItem(BRONZE_ACCESS)).revertedWith(
// 		// 		'ItemUnavailable()'
// 		// 	)
// 		// })
// 	})

// 	describe('Upgrade Level', () => {
// 		beforeEach(async () => {
// 			// Adds basic, bronze and silver passes and sets both passes to live
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BASIC_ACCESS_ITEM.price),
// 					BASIC_ACCESS_ITEM.maxSupply,
// 					BASIC_ACCESS_ITEM.accessLevel,
// 					BASIC_ACCESS_ITEM.resaleRoyalty
// 				)

// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)

// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(SILVER_ACCESS_ITEM.price),
// 					SILVER_ACCESS_ITEM.maxSupply,
// 					SILVER_ACCESS_ITEM.accessLevel,
// 					SILVER_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await accessManager.setItemMintLive(BASIC_ACCESS, true)
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
// 			await accessManager.setItemMintLive(SILVER_ACCESS, true)

// 			//	await accessManager.mintItem(BASIC_ACCESS, alice.address)
// 			// await accessManager.mintItem(BASIC_ACCESS, bob.address)
// 		})
// 		it('upgrades a user to a silver pass', async () => {
// 			//	expect(await accessManager.memberLevel(alice.address)).equal(BASIC_ACCESS)

// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(1) })
// 			expect(await accessManager.memberLevel(alice.address)).equal(BRONZE_ACCESS)
// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).currentSupply).equal(1)

// 			await accessManager.upgradeLevel(SILVER_ACCESS, alice.address, { value: getBigNumber(1) })
// 			expect(await accessManager.memberLevel(alice.address)).equal(SILVER_ACCESS)
// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).currentSupply).equal(0)
// 			expect((await accessManager.itemDetails(SILVER_ACCESS)).currentSupply).equal(1)
// 			// expect((await accessManager.itemDetails(BASIC_ACCESS)).currentSupply).equal(2)
// 		})
// 		it('prevents upgrade beyond basic without updateLevel function', async () => {
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(1) })
// 			console.log('here')
// 			expect(await accessManager.memberLevel(alice.address)).equal(BRONZE_ACCESS)

// 			await expect(
// 				accessManager.connect(alice).mintItem(SILVER_ACCESS, alice.address, {
// 					value: getBigNumber(SILVER_ACCESS_ITEM.price * BRONZE_DISCOUNT)
// 				})
// 			).revertedWith('InvalidItem()')
// 		})
// 		it('prevents upgrade to non level item (above id = GOLD = 11)', async () => {
// 			await accessManager.mintItem(BASIC_ACCESS, alice.address, { value: getBigNumber(0) })

// 			await expect(
// 				accessManager.upgradeLevel(12, alice.address, { value: getBigNumber(1) })
// 			).revertedWith('InvalidItem()')
// 		})
// 		it('prevents upgrade to same level or lower', async () => {
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(1) })

// 			await expect(
// 				accessManager.upgradeLevel(BRONZE_ACCESS, alice.address, { value: getBigNumber(0) })
// 			).revertedWith('InvalidItem()')
// 		})
// 		it('prevents upgrade if user does not already have level', async () => {
// 			await expect(
// 				accessManager.upgradeLevel(BRONZE_ACCESS, owner.address, {
// 					value: getBigNumber(BRONZE_ACCESS_ITEM.price)
// 				})
// 			).revertedWith('Unauthorised()')
// 		})
// 	})

// 	describe('Mint Access Item', () => {
// 		beforeEach(async () => {
// 			// Adds 4 passes and sets all passes to live (so we are above itemId = 8 to add non level passes)
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BASIC_ACCESS_ITEM.price),
// 					BASIC_ACCESS_ITEM.maxSupply,
// 					BASIC_ACCESS_ITEM.accessLevel,
// 					BASIC_ACCESS_ITEM.resaleRoyalty
// 				)

// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)

// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(SILVER_ACCESS_ITEM.price),
// 					SILVER_ACCESS_ITEM.maxSupply,
// 					SILVER_ACCESS_ITEM.accessLevel,
// 					SILVER_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(GOLD_ACCESS_ITEM.price),
// 					GOLD_ACCESS_ITEM.maxSupply,
// 					GOLD_ACCESS_ITEM.accessLevel,
// 					GOLD_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(BASIC_FEATURE_ITEM.price),
// 					BASIC_FEATURE_ITEM.maxSupply,
// 					BASIC_FEATURE_ITEM.accessLevel,
// 					BASIC_FEATURE_ITEM.resaleRoyalty
// 				)
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(SPECIAL_FEATURE_SILVER_ITEM.price),
// 					SPECIAL_FEATURE_SILVER_ITEM.maxSupply,
// 					SPECIAL_FEATURE_SILVER_ITEM.accessLevel,
// 					SPECIAL_FEATURE_SILVER_ITEM.resaleRoyalty
// 				)
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					getBigNumber(SPECIAL_FEATURE_GOLD_ITEM.price),
// 					SPECIAL_FEATURE_GOLD_ITEM.maxSupply,
// 					SPECIAL_FEATURE_GOLD_ITEM.accessLevel,
// 					SPECIAL_FEATURE_GOLD_ITEM.resaleRoyalty
// 				)
// 			// await accessManager
// 			// 	.connect(owner)
// 			// 	.addItem(
// 			// 		getBigNumber(BASIC_FEATURE_ITEM.price),
// 			// 		BASIC_FEATURE_ITEM.maxSupply,
// 			// 		BASIC_FEATURE_ITEM.accessLevel,
// 			// 		BASIC_FEATURE_ITEM.name,
// 			// 		BASIC_FEATURE_ITEM.description,
// 			// 		SILVER_SVG
// 			// 	)
// 			await accessManager.setItemMintLive(BASIC_ACCESS, true)
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
// 			await accessManager.setItemMintLive(SILVER_ACCESS, true)
// 			await accessManager.setItemMintLive(GOLD_ACCESS, true)
// 			await accessManager.setItemMintLive(BASIC_ITEM, true)
// 			await accessManager.setItemMintLive(SILVER_ITEM, true)
// 			await accessManager.setItemMintLive(GOLD_ITEM, true)

// 			await accessManager.mintItem(BASIC_ACCESS, alice.address)
// 		})
// 		it('denies mint of missing or non live item', async () => {
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, false)
// 			await expect(
// 				accessManager.mintItem(BRONZE_ACCESS, alice.address, {
// 					value: getBigNumber(BRONZE_ACCESS_ITEM.price)
// 				})
// 			).revertedWith('MintingClosed()')
// 		})
// 		// The below completely restricted users from accessing features on higher levels
// 		// I think removing this and keeping the possibility open is better overall
// 		// it('denies mint for member of lower level', async () => {
// 		// 	await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(BRONZE_ACCESS_ITEM.price) })
// 		// 	await expect(
// 		// 		accessManager
// 		// 			.connect(alice)
// 		// 			.mintItem(SILVER_ITEM, { value: getBigNumber(2 * BRONZE_DISCOUNT) })
// 		// 	).revertedWith('InsufficientLevel()')
// 		// })
// 		it('denies item mint for non user (no basic access pass)', async () => {
// 			await expect(
// 				accessManager.mintItem(BASIC_ITEM, bob.address, {
// 					value: getBigNumber(BASIC_FEATURE_ITEM.price)
// 				})
// 			).revertedWith('Unauthorised()')
// 		})
// 		it('denies mint for incorrect funds (member of level X should not pay for item of level X)', async () => {
// 			await accessManager.mintItem(SILVER_ACCESS, alice.address, { value: getBigNumber(2) })
// 			await expect(
// 				accessManager.mintItem(SILVER_ITEM, alice.address, { value: getBigNumber(1) })
// 			).revertedWith('IncorrectValue()')
// 		})
// 		it('denies mint for incorrect funds (member of lower level should pay correct amount)', async () => {
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, {
// 				value: getBigNumber(BRONZE_ACCESS_ITEM.price)
// 			})
// 			await expect(
// 				accessManager.mintItem(SILVER_ITEM, alice.address, { value: getBigNumber(1) })
// 			).revertedWith('IncorrectValue()')
// 		})
// 		it('mints same (or lower) level item for user', async () => {
// 			await accessManager.mintItem(SILVER_ACCESS, alice.address, {
// 				value: getBigNumber(SILVER_ACCESS_ITEM.price)
// 			})
// 			// member does not need to pay since they are already at silver level
// 			await accessManager.mintItem(SILVER_ITEM, alice.address)

// 			expect(await accessManager.balanceOf(alice.address, SILVER_ITEM)).equal(1)
// 			expect((await accessManager.itemDetails(SILVER_ITEM)).currentSupply).equal(1)
// 		})
// 		// checks minting of higher level items at all discount rates
// 		it('bronze level mints silver at discount', async () => {
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, {
// 				value: getBigNumber(BRONZE_ACCESS_ITEM.price)
// 			})
// 			await accessManager.mintItem(SILVER_ITEM, alice.address, {
// 				value: getBigNumber(SPECIAL_FEATURE_SILVER_ITEM.price * BRONZE_DISCOUNT)
// 			})

// 			expect(await accessManager.balanceOf(alice.address, SILVER_ITEM)).equal(1)
// 			expect((await accessManager.itemDetails(SILVER_ITEM)).currentSupply).equal(1)
// 		})
// 		it('bronze level mints gold at discount', async () => {
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, {
// 				value: getBigNumber(BRONZE_ACCESS_ITEM.price)
// 			})

// 			await accessManager.mintItem(GOLD_ITEM, alice.address, {
// 				value: getBigNumber(SPECIAL_FEATURE_GOLD_ITEM.price * BRONZE_DISCOUNT)
// 			})

// 			expect(await accessManager.balanceOf(alice.address, GOLD_ITEM)).equal(1)
// 			expect((await accessManager.itemDetails(GOLD_ITEM)).currentSupply).equal(1)
// 		})
// 		it('silver level mints gold at discount', async () => {
// 			await accessManager.mintItem(SILVER_ACCESS, alice.address, {
// 				value: getBigNumber(SILVER_ACCESS_ITEM.price)
// 			})
// 			await accessManager.mintItem(GOLD_ITEM, alice.address, {
// 				value: getBigNumber(SPECIAL_FEATURE_GOLD_ITEM.price * SILVER_DISCOUNT)
// 			})

// 			expect(await accessManager.balanceOf(alice.address, GOLD_ITEM)).equal(1)
// 			expect((await accessManager.itemDetails(GOLD_ITEM)).currentSupply).equal(1)
// 		})
// 		// it('denies mint of higher level item for insufficent funds', async () => {
// 		// 	await accessManager.mintItem(SILVER_ACCESS, alice.address, { value: getBigNumber(2) })
// 		// 	await accessManager.mintItem(SILVER_ITEM, alice.address, { value: getBigNumber(2) })

// 		// 	expect(await accessManager.balanceOf(alice.address, SILVER_ITEM)).equal(1)
// 		// 	expect((await accessManager.itemDetails(SILVER_ITEM)).currentSupply).equal(1)
// 		// })
// 		// missing basic item???
// 		// it('mints item for whitelist user', async () => {
// 		// 	await accessManager.connect(owner).toggleItemWhitelist(alice.address, SILVER_ITEM)
// 		// 	// await accessManager.mintItem(SILVER_ACCESS, alice.address, { value: getBigNumber(2) })
// 		// 	await accessManager.connect(alice).whitelistMintItem(SILVER_ITEM)

// 		// 	expect(await accessManager.balanceOf(alice.address, SILVER_ITEM)).equal(1)
// 		// 	expect((await accessManager.itemDetails(SILVER_ITEM)).currentSupply).equal(1)
// 		// })
// 		it('denies mint for item already at max supply', async () => {
// 			await accessManager.mintItem(GOLD_ACCESS, alice.address, { value: getBigNumber(3) })
// 			await accessManager.mintItem(GOLD_ACCESS, bob.address, { value: getBigNumber(3) })

// 			await accessManager.mintItem(SILVER_ITEM, alice.address)
// 			await accessManager.mintItem(SILVER_ITEM, bob.address)

// 			await accessManager.mintItem(BASIC_ACCESS, owner.address)

// 			await expect(
// 				accessManager.mintItem(SILVER_ITEM, owner.address, { value: getBigNumber(2) })
// 			).revertedWith('ItemUnavailable()')
// 		})
// 		it('prevents user minting multiple of the same item pass', async () => {
// 			await accessManager.mintItem(GOLD_ACCESS, alice.address, { value: getBigNumber(3) })
// 			await accessManager.mintItem(SILVER_ITEM, alice.address)

// 			await expect(accessManager.mintItem(SILVER_ITEM, alice.address)).revertedWith(
// 				'AlreadyOwner()'
// 			)
// 		})
// 	})

// 	// TODO
// 	// VERY IMPORTANT to double check all possibilites of tranfer / sell
// 	// NEED to be sure all access levels + tokens are updated correctly

// 	// Selling of access passes will be handled in a seperate aucion contract
// 	describe('Transferring and Reselling Items', () => {
// 		beforeEach(async () => {
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					SILVER_ACCESS_ITEM.maxSupply,
// 					SILVER_ACCESS_ITEM.accessLevel,
// 					getBigNumber(SILVER_ACCESS_ITEM.price),
// 					SILVER_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					GOLD_ACCESS_ITEM.maxSupply,
// 					GOLD_ACCESS_ITEM.accessLevel,
// 					getBigNumber(GOLD_ACCESS_ITEM.price),
// 					GOLD_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await accessManager.mintItem(BASIC_ACCESS, bob.address, { value: getBigNumber(0) })
// 			await accessManager.mintItem(BASIC_ACCESS, alice.address, { value: getBigNumber(0) })

// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(1) })
// 		})
// 		it('checks if ERC2981 interface supported', async () => {
// 			expect(await accessManager.supportsInterface('0x2a55205a')).equal(true)
// 		})
// 		it('transfers a token from owner to other account, checks updated levels', async () => {
// 			expect(await accessManager.balanceOf(alice.address, BRONZE_ACCESS)).equal(1)

// 			await accessManager
// 				.connect(alice)
// 				.safeTransferFrom(alice.address, bob.address, BRONZE_ACCESS, 1, '0x00')

// 			// Expect adjusted access levels to be correct
// 			expect(await accessManager.balanceOf(alice.address, BRONZE_ACCESS)).equal(0)
// 			expect(await accessManager.memberLevel(alice.address)).equal(BASIC_ACCESS)
// 			expect(await accessManager.balanceOf(bob.address, BRONZE_ACCESS)).equal(1)
// 			expect(await accessManager.memberLevel(bob.address)).equal(BRONZE_ACCESS)

// 			// Expect overall counts of tokens to remain consistent
// 			expect((await accessManager.itemDetails(BASIC_ACCESS)).currentSupply).equal(2)
// 			expect((await accessManager.itemDetails(BRONZE_ACCESS)).currentSupply).equal(1)
// 		})
// 		it('denies a transfer if not item owner', async () => {
// 			await expect(
// 				accessManager.connect(bob).safeTransferFrom(alice.address, bob.address, 1, 1, '0x00')
// 			).revertedWith('Unauthorised()')
// 		})
// 		it('checks royalties info for resale on bronze token', async () => {
// 			// await accessManager.mintItem(BRONZE_ACCESS, alice.address, { value: getBigNumber(1) })
// 			const royalties = await accessManager.royaltyInfo(
// 				BRONZE_ACCESS,
// 				getBigNumber(BRONZE_ACCESS_ITEM.price)
// 			)
// 			expect(ethers.utils.formatEther(royalties.royaltyAmount.toString())).equal('0.01')
// 		})
// 		it('checks royalties info for resale on silver token', async () => {
// 			const royalties = await accessManager.royaltyInfo(
// 				SILVER_ACCESS,
// 				getBigNumber(SILVER_ACCESS_ITEM.price)
// 			)
// 			expect(ethers.utils.formatEther(royalties.royaltyAmount.toString())).equal('0.04')
// 		})
// 		it('checks royalties info for resale on gold token', async () => {
// 			const royalties = await accessManager.royaltyInfo(
// 				GOLD_ACCESS,
// 				getBigNumber(GOLD_ACCESS_ITEM.price)
// 			)
// 			expect(ethers.utils.formatEther(royalties.royaltyAmount.toString())).equal('0.09')
// 		})
// 	})

// 	describe('Admin Operations', () => {
// 		it('withdraws funds if contract owner', async () => {
// 			await accessManager
// 				.connect(owner)
// 				.addItem(
// 					BRONZE_ACCESS_ITEM.maxSupply,
// 					BRONZE_ACCESS_ITEM.accessLevel,
// 					getBigNumber(BRONZE_ACCESS_ITEM.price),
// 					BRONZE_ACCESS_ITEM.resaleRoyalty
// 				)
// 			await accessManager.setItemMintLive(BRONZE_ACCESS, true)
// 			await accessManager.mintItem(BRONZE_ACCESS, alice.address, {
// 				value: getBigNumber(BRONZE_ACCESS_ITEM.price)
// 			})

// 			const accessManagerBalancePrev = await ethers.provider.getBalance(accessManager.address)
// 			const ownerBalancePrev = await ethers.provider.getBalance(owner.address)
// 			console.log(accessManagerBalancePrev, ownerBalancePrev)

// 			await accessManager.connect(owner).collectFees()

// 			const accessManagerBalanceAfter = await ethers.provider.getBalance(accessManager.address)
// 			const ownerBalanceAfter = await ethers.provider.getBalance(owner.address)
// 			console.log(accessManagerBalancePrev.sub(accessManagerBalanceAfter))

// 			expect(accessManagerBalancePrev.sub(accessManagerBalanceAfter)).equal(getBigNumber(1))
// 			expect(ownerBalancePrev.lt(ownerBalanceAfter))
// 		})
// 		it('prevents non owner from withdrawing', async () => {
// 			await expect(accessManager.connect(alice).collectFees()).revertedWith('NotOwner()')
// 		})
// 		it('prevent transfer ownership from non owner', async () => {
// 			await expect(accessManager.connect(alice).setOwner(alice.address)).revertedWith('NotOwner()')
// 		})
// 		it('transfer ownership', async () => {
// 			await accessManager.connect(owner).setOwner(alice.address)
// 			expect(await accessManager.owner()).equal(alice.address)
// 		})
// 	})
// })
