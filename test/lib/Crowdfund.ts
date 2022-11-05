import { expect } from '../utils/expect'

import { TOKEN, ZERO_ADDRESS } from '../config'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber, Contract, ContractFactory, ethers, Signer } from 'ethers'
import { deployments, ethers as hardhatEthers } from 'hardhat'
import { beforeEach, describe, it } from 'mocha'
import { advanceTime } from '../utils/helpers'

// Defaults to e18 using amount * 10^18
function getBigNumber(amount: number, decimals = 18) {
	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals))
}

describe.only('Crowdfund', function () {
	let forum: Contract // ForumGroup contract instance
	let crowdfund: Contract // Crowdfund contract instance
	let proposer: SignerWithAddress // signerA
	let alice: SignerWithAddress // signerB
	let bob: SignerWithAddress // signerC
	let crowdsaleInput: any // demo input for crowdsale
	let testGroupNameHash: string // hash of test group name, used to locate crowdfun on contract

	beforeEach(async () => {
		;[proposer, alice, bob] = await hardhatEthers.getSigners()

		// Similar to deploying the master forum multisig
		await deployments.fixture(['Forum', 'Shields'])
		forum = await hardhatEthers.getContract('ForumGroup')
		crowdfund = await hardhatEthers.getContract('ForumCrowdfund')

		crowdsaleInput = {
			targetContract: ZERO_ADDRESS,
			targetPrice: getBigNumber(1),
			deadline: 1730817411, // 05-11-2030
			groupName: 'TEST',
			symbol: 'T',
			payload: ethers.utils.toUtf8Bytes('0X123')
		}

		testGroupNameHash = ethers.utils.keccak256(
			ethers.utils.defaultAbiCoder.encode(['string'], [crowdsaleInput.groupName])
		)
		console.log('testGroupNameHash', testGroupNameHash)
	})
	it('Should initiate crowdsale and submit contribution', async function () {
		await crowdfund.initiateCrowdfund(crowdsaleInput, { value: getBigNumber(1) })

		const crowdfundDetails = await crowdfund.getCrowdfund(testGroupNameHash)
		console.log({ crowdfundDetails })

		// Check initial state
		expect(crowdfundDetails.parameters.targetContract).to.equal(crowdsaleInput.targetContract)
		expect(crowdfundDetails.parameters.targetPrice).to.equal(crowdsaleInput.targetPrice)
		expect(crowdfundDetails.parameters.deadline).to.equal(crowdsaleInput.deadline)
		expect(crowdfundDetails.parameters.groupName).to.equal(crowdsaleInput.groupName)
		expect(crowdfundDetails.parameters.symbol).to.equal(crowdsaleInput.symbol)
		//expect(crowdfundDetails.payload).to.equal(crowdsaleInput.payload)

		await crowdfund.submitContribution(testGroupNameHash),
			{
				value: getBigNumber(1)
			}

		const crowdfundDetailsAfterSubmission = await crowdfund.getCrowdfund(testGroupNameHash)

		// Check updated state
		console.log(crowdfundDetailsAfterSubmission.contributors)
		console.log(crowdfundDetailsAfterSubmission.contributions)
		expect(crowdfundDetailsAfterSubmission.contributors).to.have.lengthOf(2)
		expect(crowdfundDetailsAfterSubmission.contributions).to.have.lengthOf(2)
		expect(crowdfundDetailsAfterSubmission.parameters.targetContract).to.equal(
			crowdsaleInput.targetContract
		)
	})
	// TODO need a check for previously deployed group with same name - create2 will fail, we should catch this
	it.skip('Should revert if crowdsale for duplicate name exists', async function () {
		await crowdfund.initiateCrowdfund(crowdsaleInput, { value: getBigNumber(1) })

		await expect(crowdfund.initiateCrowdfund(crowdsaleInput)).to.be.revertedWith('OpenFund()')
	})
	it('Should revert submitting a contribution if no fund exists, over 12 people, or incorrect value', async function () {
		await crowdfund.initiateCrowdfund(crowdsaleInput)

		// Check if fund already exists
		await expect(crowdfund.submitContribution('WRONG')).to.be.revertedWith('OpenFund()')

		// Check max contributors limit
		const [a, b, c, d, e, f, g, h, i, j, k, l, m] = await hardhatEthers.getSigners()
		const sigs: SignerWithAddress[] = [a, b, c, d, e, f, g, h, i, j, k, l, m]

		for (let i = 0; i < sigs.length; i++) {
			if (i < 11) {
				await crowdfund.connect(sigs[i]).submitContribution(testGroupNameHash),
					{
						value: getBigNumber(1)
					}
			} else {
				await expect(crowdfund.connect(sigs[i]).submitContribution(testGroupNameHash), {
					value: getBigNumber(1)
				}).to.be.revertedWith('MemberLimitReached()')
			}
		}
	})
	it.only('Should cancel a crowdfund and revert if not cancellable', async function () {
		await crowdfund.initiateCrowdfund(crowdsaleInput, { value: getBigNumber(1) })

		// Can not cancel before deadline
		await expect(crowdfund.cancelCrowdfund(testGroupNameHash)).to.be.revertedWith('OpenFund()')

		advanceTime(1730817412)

		// Cancel the crowdfund and check the balance has been returned
		const bal1 = await hardhatEthers.provider.getBalance(proposer.address)
		await crowdfund.cancelCrowdfund(testGroupNameHash)
		const bal2 = await hardhatEthers.provider.getBalance(proposer.address)
		expect(bal2).to.be.gt(bal1)
	})

	// it('Should process native `value` crowdfund with unitValue multiplier', async function () {
	// 	// Delete existing crowdfund for test
	// 	await crowdfund.cancelFundRound(forum.address);

	// 	// unitValue = 2/1 so the contributors should get 1/2 of their contribution in group tokens
	// 	await crowdfund
	// 		.connect(proposer)
	// 		.initiateFundRound(
	// 			forum.address,
	// 			hardhatEthers.utils.parseEther('2'),
	// 			hardhatEthers.utils.parseEther('1'),
	// 			{ value: getBigNumber(50) }
	// 		);

	// 	await crowdfund
	// 		.connect(alice)
	// 		.submitFundContribution(forum.address, { value: getBigNumber(50) });

	// 	await crowdfund.processFundRound(forum.address);

	// 	// After processing, the accounts should be given tokens, and dao balance should be updated
	// 	expect(await hardhatEthers.provider.getBalance(forum.address)).to.equal(
	// 		getBigNumber(100)
	// 	);
	// 	expect(await hardhatEthers.provider.getBalance(crowdfund.address)).to.equal(
	// 		getBigNumber(0)
	// 	);
	// 	// Token balaces are 25 -> 1/2 of 50 as we have applied the unitValue multiplier
	// 	expect(await forum.balanceOf(proposer.address, TOKEN)).to.equal(
	// 		getBigNumber(25)
	// 	);
	// 	expect(await forum.balanceOf(alice.address, TOKEN)).to.equal(
	// 		getBigNumber(25)
	// 	);

	// 	// unitValue = 1/2 so the contributors should get 2 times their contribution in group tokens
	// 	await crowdfund
	// 		.connect(proposer)
	// 		.initiateFundRound(
	// 			forum.address,
	// 			hardhatEthers.utils.parseEther('1'),
	// 			hardhatEthers.utils.parseEther('2'),
	// 			{ value: getBigNumber(50) }
	// 		);

	// 	await crowdfund
	// 		.connect(alice)
	// 		.submitFundContribution(forum.address, { value: getBigNumber(50) });

	// 	await crowdfund.processFundRound(forum.address);

	// 	// After processing, the accounts should be given tokens, and dao balance should be updated (200 since second crowdfund)
	// 	expect(await hardhatEthers.provider.getBalance(forum.address)).to.equal(
	// 		getBigNumber(200)
	// 	);
	// 	expect(await hardhatEthers.provider.getBalance(crowdfund.address)).to.equal(
	// 		getBigNumber(0)
	// 	);
	// 	// Token balaces are 125 -> 1/2 of 50 from prev fun + 100 from current
	// 	expect(await forum.balanceOf(proposer.address, TOKEN)).to.equal(
	// 		getBigNumber(125)
	// 	);
	// 	expect(await forum.balanceOf(alice.address, TOKEN)).to.equal(
	// 		getBigNumber(125)
	// 	);
	// });
	// it('Should revert if non member initiates funraise', async function () {
	// 	// Delete existing crowdfund for test
	// 	await crowdfund.cancelFundRound(forum.address);

	// 	await expect(
	// 		crowdfund
	// 			.connect(bob)
	// 			.initiateFundRound(forum.address, 1, 1, { value: getBigNumber(50) })
	// 	).revertedWith('NotMember()');
	// });
	// it('Should revert if a fund is already open', async function () {
	// 	await expect(
	// 		crowdfund
	// 			.connect(proposer)
	// 			.initiateFundRound(forum.address, 1, 1, { value: getBigNumber(50) })
	// 	).revertedWith('OpenFund()');
	// });
	// it('Should revert if incorrect value sent', async function () {
	// 	await expect(
	// 		crowdfund
	// 			.connect(alice)
	// 			.submitFundContribution(forum.address, { value: getBigNumber(5000) })
	// 	).revertedWith('IncorrectContribution()');
	// });
	// it('Should revert if no fund is open', async function () {
	// 	// Delete other crowdfund
	// 	await crowdfund.cancelFundRound(forum.address);

	// 	// Need to set value to 0 as there is no individualContribution set yet
	// 	await expect(
	// 		crowdfund
	// 			.connect(alice)
	// 			.submitFundContribution(forum.address, { value: 0 })
	// 	).revertedWith('FundraiseMissing()');
	// });
	// it('Should revert if not all members have contributed', async function () {
	// 	await expect(crowdfund.processFundRound(forum.address)).revertedWith(
	// 		'MembersMissing()'
	// 	);
	// });

	// it('Should revert if non group member taking part', async function () {
	// 	await expect(
	// 		crowdfund
	// 			.connect(bob)
	// 			.submitFundContribution(forum.address, { value: getBigNumber(50) })
	// 	).revertedWith('NotMember()');
	// });
	// it('Should revert if user is depositing twice', async function () {
	// 	await expect(
	// 		crowdfund
	// 			.connect(proposer)
	// 			.submitFundContribution(forum.address, { value: getBigNumber(50) })
	// 	).revertedWith('IncorrectContribution()');
	// });
	// it('Should cancel round only if cancelled by proposer or dao, and return funds', async function () {
	// 	await expect(
	// 		crowdfund.connect(alice).cancelFundRound(forum.address)
	// 	).revertedWith('NotProposer()');

	// 	await crowdfund.connect(proposer).cancelFundRound(forum.address);

	// 	const deletedFund = await crowdfund.getFund(forum.address);
	// 	expect(deletedFund.individualContribution).to.equal(getBigNumber(0));
	// 	expect(deletedFund.valueNumerator).to.equal(getBigNumber(0));
	// 	expect(deletedFund.valueDenominator).to.equal(getBigNumber(0));
	// });
})
