import { advanceTime } from './helpers'

import { BigNumber, Contract, ContractTransaction } from 'ethers'

type ProposalProcessed = {
	tx: ContractTransaction
	proposalType: number
	proposal: number
	didProposalPass: boolean
}

export async function voteProposal(
	forum: Contract,
	signer: any,
	propNumber: number,
	proposalDetails: {
		type: number
		accounts: string[]
		amounts: number[] | BigNumber[]
		payloads: any[]
	}
): Promise<ProposalProcessed> {
	await forum
		.connect(signer)
		.propose(
			proposalDetails.type,
			proposalDetails.accounts,
			proposalDetails.amounts,
			proposalDetails.payloads
		)

	await forum.connect(signer).vote(propNumber)
	await advanceTime(35)
	const tx = await (await forum.processProposal(propNumber)).wait()

	// Proposal info will always be the last event
	const eventIndex = tx.events?.length - 1

	const proposalType = tx.events?.[eventIndex].args?.proposalType
	const proposal = tx.events?.[eventIndex].args?.proposal
	const didProposalPass = tx.events?.[eventIndex].args?.didProposalPass

	//console.log(`Proposal: ${proposal} of type ${proposalType}, didPass = ${didProposalPass}`)

	return { tx, proposalType, proposal, didProposalPass }
}
