import { advanceTime } from './helpers'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber, Contract, ContractTransaction } from 'ethers'
import { ethers as hardhatEthers } from 'hardhat'

const formatDomain = (verifyingContract) => {
	return {
		name: 'FORUM',
		version: '1',
		chainId: 43114,
		verifyingContract: verifyingContract
	}
}

const types = {
	SignProposal: [{ name: 'proposal', type: 'uint256' }]
}

const formatValue = (signer, proposal) => {
	return {
		signer: signer,
		proposal: proposal
	}
}

type ProposalProcessed = {
	tx: ContractTransaction
	proposalType: number
	proposal: number
	didProposalPass: boolean
}

export async function processProposal(
	forum: Contract,
	signers: SignerWithAddress[],
	propNumber: number,
	proposalDetails: {
		type: number
		accounts: string[]
		amounts: number[] | BigNumber[]
		payloads: any[]
	}
): Promise<ProposalProcessed> {
	interface Signature {
		v: number
		r: string
		s: string
	}

	let sigs: Signature[] = []

	await forum
		.connect(signers[0])
		.propose(
			proposalDetails.type,
			proposalDetails.accounts,
			proposalDetails.amounts,
			proposalDetails.payloads
		)

	for (let i = 0; i < signers.length; i++) {
		const signature = await signers[i]._signTypedData(
			formatDomain(forum.address),
			types,
			formatValue(signers[i].address, propNumber)
		)
		const { r, s, v } = hardhatEthers.utils.splitSignature(signature)
		sigs.push({ v, r, s })
	}

	await advanceTime(35)
	const tx = await (await forum.processProposal(propNumber, sigs)).wait()
	//console.log(tx)

	// Proposal info will always be the last event
	const eventIndex = tx.events?.length - 1

	const proposalType = tx.events?.[eventIndex].args?.proposalType
	const proposal = tx.events?.[eventIndex].args?.proposal
	const didProposalPass = tx.events?.[eventIndex].args?.didProposalPass

	//console.log(`Proposal: ${proposal} of type ${proposalType}, didPass = ${didProposalPass}`)

	return { tx, proposalType, proposal, didProposalPass }
}
