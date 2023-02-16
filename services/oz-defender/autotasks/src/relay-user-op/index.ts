import EntryPoint from '../../../../../out/EntryPoint.sol/EntryPoint.json'
import { relayInputGenerator } from '../relayInputGenerator'

async function relay(entryPoint, body, whitelist) {
	const { userOp, gas } = body

	// Decide if we want to relay this request based on a whitelist
	const accepts = !whitelist || whitelist.includes(entryPoint.address)
	if (!accepts) throw new Error(`Rejected request to ${entryPoint.address}`)

	// Send meta-tx through relayer to the entryPoint contract
	const gasLimit = (parseInt(gas) + 50000).toString()

	return await entryPoint.handleOps([userOp], '0x0000000000000000000000000000000000000000', {
		gasLimit
	})
}

async function handler(event) {
	// Generate relay input params
	const { targetContract, body, whitelist } = await relayInputGenerator(event, EntryPoint.abi)
	// Relay transaction
	const tx = await relay(targetContract, body, whitelist)

	console.log(`Sent meta-tx: ${tx.hash}`)
	return { txHash: tx.hash }
}

export { handler, relay }
