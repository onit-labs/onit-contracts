import { BigNumber, BigNumberish, Contract, ContractTransaction } from 'ethers'

type ShieldBuilt = {
	tx: ContractTransaction
	// tokenId: number
	shieldHash: string
}

export async function buildShield(
	shields: Contract,
	params: {
		field: number
		hardware: number[]
		frame: number
		colors: [BigNumberish, BigNumberish, BigNumberish, BigNumberish]
		fee: BigNumber
		tokenId: BigNumberish
	}
): Promise<ShieldBuilt> {
	const tx = await (
		await shields.buildShield(
			params.field,
			params.hardware,
			params.frame,
			params.colors,
			params.tokenId,
			{
				value: params.fee
			}
		)
	).wait()

	let eventIndex = 0

	// There can be up to 3 events emitted by the shield contract when building
	// The final one will always be the shield build event
	if (tx.events?.[1] != null) {
		console.log('Using 2nd event as shield built event')
		eventIndex = 1
	}
	if (tx.events?.[2] != null) {
		console.log('Using 3rd event as shield built event')
		eventIndex = 2
	}

	const shieldHash = tx.events?.[eventIndex].args?.newShieldHash

	console.log(`Token ID: ${params.tokenId}, Shield Hash: ${shieldHash}`)

	return { tx, shieldHash }
}
