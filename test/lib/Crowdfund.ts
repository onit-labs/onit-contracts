import { expect } from '../utils/expect';

import { TOKEN, ZERO_ADDRESS } from '../config';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber, Contract, ContractFactory, ethers, Signer } from 'ethers';
import { parseEther } from 'ethers/lib/utils';
import { deployments, ethers as hardhatEthers } from 'hardhat';
import { beforeEach, describe, it } from 'mocha';

// Defaults to e18 using amount * 10^18
function getBigNumber(amount: number, decimals = 18) {
	return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
}

describe.only('Crowdfund', function () {
	let forum: Contract; // ForumGroup contract instance
	let crowdfund: Contract; // Fundraise contract instance
	let proposer: SignerWithAddress; // signerA
	let alice: SignerWithAddress; // signerB
	let bob: SignerWithAddress; // signerC
	let crowdsaleInput: any;

	beforeEach(async () => {
		[proposer, alice, bob] = await hardhatEthers.getSigners();

		// TODO implement non avax funding in version 2

		// Similar to deploying the master forum multisig
		await deployments.fixture(['Forum', 'Shields']);
		forum = await hardhatEthers.getContract('ForumGroup');
		crowdfund = await hardhatEthers.getContract('ForumCrowdfund');

		crowdsaleInput = {
			creator: proposer.address,
			targetContract: ZERO_ADDRESS,
			targetPrice: getBigNumber(1),
			deadline: 1000000,
			groupName: 'TEST',
			symbol: 'T',
			calldata: '0X123',
		};
	});
	it('Should initiate crowdsale', async function () {
		await crowdfund.initiateCrowdfund(
			proposer.address,
			ZERO_ADDRESS,
			getBigNumber(1),
			1000000,
			ethers.utils.formatBytes32String('TEST'),
			ethers.utils.formatBytes32String('T'),
			ethers.utils.formatBytes32String('0X123')
		);

		const cf = await crowdfund.getCrowdfund(
			ethers.utils.formatBytes32String(crowdsaleInput.groupName)
		);

		// Check initial state
		expect(cf.deadline).to.equal(crowdsaleInput.deadline);

		// await crowdfund
		// 	.connect(alice)
		// 	.submitFundContribution(forum.address, { value: getBigNumber(50) });

		// const deets = await crowdfund.getFund(forum.address);

		// console.log(deets.individualContribution.toString());
		// console.log(deets.contributors);
		// console.log(deets.valueNumerator.toString());
		// console.log(deets.valueDenominator.toString());

		// // Check state after second contribution
		// expect(
		// 	(await crowdfund.getFund(forum.address)).contributors.length
		// ).to.equal(2);
		// expect(
		// 	(await crowdfund.getFund(forum.address)).individualContribution
		// ).to.equal(getBigNumber(50));

		// await crowdfund.processFundRound(forum.address);

		// // After processing, the accounts should be given tokens, and dao balance should be updated
		// expect(await hardhatEthers.provider.getBalance(forum.address)).to.equal(
		// 	getBigNumber(100)
		// );
		// expect(await hardhatEthers.provider.getBalance(crowdfund.address)).to.equal(
		// 	getBigNumber(0)
		// );
		// expect(await forum.balanceOf(proposer.address, TOKEN)).to.equal(
		// 	getBigNumber(50)
		// );
		// expect(await forum.balanceOf(alice.address, TOKEN)).to.equal(
		// 	getBigNumber(50)
		// );
	});
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
});
