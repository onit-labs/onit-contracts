import { DefenderRelayProvider, DefenderRelaySigner } from 'defender-relay-client/lib/ethers'
import { Contract } from '@ethersproject/contracts'

export async function relayInputGenerator(event, abi) {
	if (!event.request || !event.request.body) throw new Error(`Missing payload`)

	// Get data from event payload
	const { mumbai_entry_point_address, polygon_entry_point_address } = event.secrets
	const body = event.request.body
	const whitelist = event.whitelist || null

	console.log(`Relaying`, body)

	// Initialize Relayer provider and signer, and forwarder contract
	const credentials = { ...event }

	const provider = new DefenderRelayProvider(credentials)

	const signer = new DefenderRelaySigner(credentials, provider, {
		speed: 'fast'
	})

	// Depending on chain use appropriate entry point
	const targetContract = new Contract(
		body.chain == '137' ? polygon_entry_point_address : mumbai_entry_point_address,
		abi,
		signer
	)

	return { signer, targetContract, body, whitelist }
}

export {}
