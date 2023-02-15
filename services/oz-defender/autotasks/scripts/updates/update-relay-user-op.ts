import { AutotaskClient } from 'defender-autotask-client'

require('dotenv').config({ path: '.env' })

async function uploadCode(autotaskId, apiKey, apiSecret) {
	const client = new AutotaskClient({ apiKey, apiSecret })
	await client.updateCodeFromFolder(autotaskId, './dist/relay-opensea')
}

async function main() {
	const {
		TEAM_API: apiKey,
		TEAM_SECRET: apiSecret,
		GOERLI_OPENSEA_RELAY_AUTOTASK_ID: goerliAutotaskId,
		AVAX_OPENSEA_RELAY_AUTOTASK_ID: avaxAutotaskId
	} = process.env

	if (!goerliAutotaskId || !avaxAutotaskId) throw new Error(`Missing autotask id`)
	await uploadCode(goerliAutotaskId, apiKey, apiSecret)
	await uploadCode(avaxAutotaskId, apiKey, apiSecret)
	console.log(`Code updated`)
}

if (require.main === module) {
	main()
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error)
			process.exit(1)
		})
}
