import EntryPoint from '../../../../../out/EntryPoint.sol/EntryPoint.json'
import { BigNumber } from '@ethersproject/bignumber'
import { relayInputGenerator } from '../relayInputGenerator'

// ! Tidy this file

async function relay(signer, entryPoint, body, whitelist) {
	const { userOp, gas } = body

	// Decide if we want to relay this request based on a whitelist
	const accepts = !whitelist || whitelist.includes(entryPoint.address)
	if (!accepts) throw new Error(`Rejected request to ${entryPoint.address}`)

	// Send meta-tx through relayer to the entryPoint contract
	const gasLimit = (parseInt(gas) + 50000).toString()

	if (userOp.initCode != '0x') {
		console.log('sending deposit to', userOp.sender)

		await entryPoint.depositTo(userOp.sender, {
			value: BigNumber.from('100000000000000000') // 0.1 matic should be enough to get started
		})
	}

	return await entryPoint.handleOps([userOp], await signer.getAddress(), {
		gasLimit
	})
}

async function handler(event) {
	// Generate relay input params
	const { signer, targetContract, body, whitelist } = await relayInputGenerator(
		event,
		EntryPoint.abi
	)
	// Relay transaction
	const tx = await relay(signer, targetContract, body, whitelist)

	console.log(`Sent meta-tx: ${tx.hash}`)
	return { txHash: tx.hash }
}

export { handler, relay }
