import { abi as ForumGroupFactoryAbi } from '../../../../../out/ForumGroupFactory.sol/ForumGroupFactory.json'
import { abi as ForumAccountFactoryAbi } from '../../../../../out/ForumAccountFactory.sol/ForumAccountFactory.json'

import { DefenderRelayProvider, DefenderRelaySigner } from 'defender-relay-client/lib/ethers'
import { Contract } from '@ethersproject/contracts'

// ! Tidy this file & type everything better !

async function relay(accountFactory, body, whitelist) {
	const { deployPayload, accountType, gas } = body

	// Decide if we want to relay this request based on a whitelist
	const accepts = !whitelist || whitelist.includes(accountFactory.address)
	if (!accepts) throw new Error(`Rejected request to ${accountFactory.address}`)

	// Send meta-tx through relayer to the accountFactory contract
	const gasLimit = (parseInt(gas) + 50000).toString()

	return accountType == 'INDIVIDUAL'
		? await accountFactory.createForumAccount(deployPayload.owner, {
				gasLimit
		  })
		: await accountFactory.deployForumGroup(
				deployPayload.name,
				deployPayload.threshold,
				deployPayload.members,
				{ gasLimit }
		  )
}

async function handler(event) {
	// ! Below should be moved to an improved version of relayInputGenerator
	if (!event.request || !event.request.body) throw new Error(`Missing payload`)

	const { Individual_Account_Factory_Address, Group_Account_Factory_Address } = event.secrets
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
	const targetContract =
		body.accountType == 'INDIVIDUAL'
			? new Contract(Individual_Account_Factory_Address, ForumAccountFactoryAbi, signer)
			: new Contract(Group_Account_Factory_Address, ForumGroupFactoryAbi, signer)

	// ! Above should be moved to an inproved version of relayInputGenerator

	// Relay transaction
	const tx = await relay(targetContract, body, whitelist)

	console.log(`Sent meta-tx: ${tx.hash}`)
	return { txHash: tx.hash }
}

export { handler, relay }
