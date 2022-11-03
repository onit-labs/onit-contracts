import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { BigNumber, Contract } from 'ethers'
import { ethers as hardhatEthers } from 'hardhat'

interface Signature {
	v: number
	r: string
	s: string
}

enum SigTypes {
	ProposalVoteSig,
	DelegateBySig
}

// TODO
// - create more general formatter for domain types, values
// - improve any type on data
export async function createSignature(
	signatureType: SigTypes,
	contract: Contract,
	signer: SignerWithAddress,
	data: any
): Promise<Signature> {
	let formattedSigningData: { domain: any; types: any; values: any }

	switch (signatureType) {
		case SigTypes.ProposalVoteSig:
			formattedSigningData = formatProposalVoteSig(contract.address, signer.address, data.proposal)
			break
		case SigTypes.DelegateBySig:
			formattedSigningData = formatDelegateBySig(contract.address, data.delegatee, data.nonce)
			break
	}

	const signature = await signer._signTypedData(
		formattedSigningData.domain,
		formattedSigningData.types,
		formattedSigningData.values
	)
	const { r, s, v } = hardhatEthers.utils.splitSignature(signature)

	return { v: v, r: r, s: s }
}

const formatProposalVoteSig = (forumAddress, voteSigner, propNumber) => {
	return {
		domain: {
			name: 'FORUM',
			version: '1',
			chainId: 43114,
			verifyingContract: forumAddress
		},
		types: {
			SignProposal: [{ name: 'proposal', type: 'uint256' }]
		},
		values: {
			signer: voteSigner,
			proposal: propNumber
		}
	}
}

const formatDelegateBySig = (forumAddress, delegatee, nonce) => {
	return {
		domain: {
			name: 'FORUM',
			version: '1',
			chainId: 43114,
			verifyingContract: forumAddress
		},
		types: {
			Delegation: [
				{ name: 'delegatee', type: 'address' },
				{ name: 'nonce', type: 'uint256' },
				{ name: 'deadline', type: 'uint256' }
			]
		},
		values: {
			delegatee: delegatee,
			nonce: nonce,
			deadline: 1941543121
		}
	}
}
