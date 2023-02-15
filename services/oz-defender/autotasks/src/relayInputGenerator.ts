import { DefenderRelayProvider, DefenderRelaySigner } from 'defender-relay-client/lib/ethers'
import { Contract } from 'ethers'

export async function relayInputGenerator(event, abi) {
	// Parse webhook payload
	if (!event.request || !event.request.body) throw new Error(`Missing payload`)

	const body = event.request.body
	const whitelist = event.whitelist || null

	console.log(`Relaying Claim`, body)

	// Initialize Relayer provider and signer, and forwarder contract
	const credentials = { ...event }
	const provider = new DefenderRelayProvider(credentials)

	const signer = new DefenderRelaySigner(credentials, provider, {
		speed: 'fast'
	})

	const targetContract = new Contract(body.contractAddress, abi, signer)

	return { targetContract, body, whitelist }
}

export {}
