import { expect } from '../utils/expect'

import { TOKEN, ZERO_ADDRESS } from '../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber, Contract, ContractFactory, ethers, Signer } from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'

// Defaults to e18 using amount * 10^18
function getBigNumber(amount: number, decimals = 18) {
	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals))
}

describe('Fundraise', function () {
	let forum: Contract // ForumGroup contract instance
	let fundraise: Contract // Fundraise contract instance
	let proposer: SignerWithAddress // signerA
	let alice: SignerWithAddress // signerB
	let bob: SignerWithAddress // signerC

	beforeEach(async () => {
		;[proposer, alice, bob] = await hardhatEthers.getSigners()

		// TODO implement non avax funding in version 2

		// Similar to deploying the master forum multisig
		await deployments.fixture(['Forum', 'Shields'])
		forum = await hardhatEthers.getContract('ForumGroup')
		fundraise = await hardhatEthers.getContract('ForumGroupFundraise')

		await forum.init(
			'FORUM',
			'FORUM',
			[proposer.address, alice.address],
			[ZERO_ADDRESS, ZERO_ADDRESS, fundraise.address],
			[30, 0, 50, 60]
		)

		// Submit Fundraise to forum with multiplier of 1
		await fundraise
			.connect(proposer)
			.initiateFundRound(
				forum.address,
				hardhatEthers.utils.parseEther('1'),
				hardhatEthers.utils.parseEther('1'),
				{ value: getBigNumber(50) }
			)
	})
	it('Should process native `value` fundraise round', async function () {
		// Check initial state
		expect((await fundraise.getFund(forum.address)).individualContribution).to.equal(
			getBigNumber(50)
		)

		await fundraise
			.connect(alice)
			.submitFundContribution(forum.address, { value: getBigNumber(50) })

		const deets = await fundraise.getFund(forum.address)

		console.log(deets.individualContribution.toString())
		console.log(deets.contributors)
		console.log(deets.valueNumerator.toString())
		console.log(deets.valueDenominator.toString())

		// Check state after second contribution
		expect((await fundraise.getFund(forum.address)).contributors.length).to.equal(2)
		expect((await fundraise.getFund(forum.address)).individualContribution).to.equal(
			getBigNumber(50)
		)

		await fundraise.processFundRound(forum.address)

		// After processing, the accounts should be given tokens, and dao balance should be updated
		expect(await hardhatEthers.provider.getBalance(forum.address)).to.equal(getBigNumber(100))
		expect(await hardhatEthers.provider.getBalance(fundraise.address)).to.equal(getBigNumber(0))
		expect(await forum.balanceOf(proposer.address, TOKEN)).to.equal(getBigNumber(50))
		expect(await forum.balanceOf(alice.address, TOKEN)).to.equal(getBigNumber(50))
	})
	it('Should process native `value` fundraise with unitValue multiplier', async function () {
		// Delete existing fundraise for test
		await fundraise.cancelFundRound(forum.address)

		// unitValue = 2/1 so the contributors should get 1/2 of their contribution in group tokens
		await fundraise
			.connect(proposer)
			.initiateFundRound(
				forum.address,
				hardhatEthers.utils.parseEther('2'),
				hardhatEthers.utils.parseEther('1'),
				{ value: getBigNumber(50) }
			)

		await fundraise
			.connect(alice)
			.submitFundContribution(forum.address, { value: getBigNumber(50) })

		await fundraise.processFundRound(forum.address)

		// After processing, the accounts should be given tokens, and dao balance should be updated
		expect(await hardhatEthers.provider.getBalance(forum.address)).to.equal(getBigNumber(100))
		expect(await hardhatEthers.provider.getBalance(fundraise.address)).to.equal(getBigNumber(0))
		// Token balaces are 25 -> 1/2 of 50 as we have applied the unitValue multiplier
		expect(await forum.balanceOf(proposer.address, TOKEN)).to.equal(getBigNumber(25))
		expect(await forum.balanceOf(alice.address, TOKEN)).to.equal(getBigNumber(25))

		// unitValue = 1/2 so the contributors should get 2 times their contribution in group tokens
		await fundraise
			.connect(proposer)
			.initiateFundRound(
				forum.address,
				hardhatEthers.utils.parseEther('1'),
				hardhatEthers.utils.parseEther('2'),
				{ value: getBigNumber(50) }
			)

		await fundraise
			.connect(alice)
			.submitFundContribution(forum.address, { value: getBigNumber(50) })

		await fundraise.processFundRound(forum.address)

		// After processing, the accounts should be given tokens, and dao balance should be updated (200 since second fundraise)
		expect(await hardhatEthers.provider.getBalance(forum.address)).to.equal(getBigNumber(200))
		expect(await hardhatEthers.provider.getBalance(fundraise.address)).to.equal(getBigNumber(0))
		// Token balaces are 125 -> 1/2 of 50 from prev fun + 100 from current
		expect(await forum.balanceOf(proposer.address, TOKEN)).to.equal(getBigNumber(125))
		expect(await forum.balanceOf(alice.address, TOKEN)).to.equal(getBigNumber(125))
	})
	it('Should revert if non member initiates funraise', async function () {
		// Delete existing fundraise for test
		await fundraise.cancelFundRound(forum.address)

		await expect(
			fundraise.connect(bob).initiateFundRound(forum.address, 1, 1, { value: getBigNumber(50) })
		).revertedWith('NotMember()')
	})
	it('Should revert if a fund is already open', async function () {
		await expect(
			fundraise
				.connect(proposer)
				.initiateFundRound(forum.address, 1, 1, { value: getBigNumber(50) })
		).revertedWith('OpenFund()')
	})
	it('Should revert if incorrect value sent', async function () {
		await expect(
			fundraise.connect(alice).submitFundContribution(forum.address, { value: getBigNumber(5000) })
		).revertedWith('IncorrectContribution()')
	})
	it('Should revert if no fund is open', async function () {
		// Delete other fundraise
		await fundraise.cancelFundRound(forum.address)

		// Need to set value to 0 as there is no individualContribution set yet
		await expect(
			fundraise.connect(alice).submitFundContribution(forum.address, { value: 0 })
		).revertedWith('FundraiseMissing()')
	})
	it('Should revert if not all members have contributed', async function () {
		await expect(fundraise.processFundRound(forum.address)).revertedWith('MembersMissing()')
	})

	it('Should revert if non group member taking part', async function () {
		await expect(
			fundraise.connect(bob).submitFundContribution(forum.address, { value: getBigNumber(50) })
		).revertedWith('NotMember()')
	})
	it('Should revert if user is depositing twice', async function () {
		await expect(
			fundraise.connect(proposer).submitFundContribution(forum.address, { value: getBigNumber(50) })
		).revertedWith('IncorrectContribution()')
	})
	it('Should cancel round only if cancelled by proposer or dao, and return funds', async function () {
		await expect(fundraise.connect(alice).cancelFundRound(forum.address)).revertedWith(
			'NotProposer()'
		)

		await fundraise.connect(proposer).cancelFundRound(forum.address)

		const deletedFund = await fundraise.getFund(forum.address)
		expect(deletedFund.individualContribution).to.equal(getBigNumber(0))
		expect(deletedFund.valueNumerator).to.equal(getBigNumber(0))
		expect(deletedFund.valueDenominator).to.equal(getBigNumber(0))
	})
})
