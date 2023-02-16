import { AutotaskClient } from 'defender-autotask-client'

require('dotenv').config({ path: '.env' })

async function uploadCode(autotaskId, apiKey, apiSecret) {
	const client = new AutotaskClient({ apiKey, apiSecret })
	await client.updateCodeFromFolder(autotaskId, './dist/relay-user-op')
}

async function main() {
	const {
		TEAM_API: apiKey,
		TEAM_SECRET: apiSecret,
		MUMBAI_USER_OP_RELAY_AUTOTASK_ID: mumbaiAutotaskId
		//AVAX_OPENSEA_RELAY_AUTOTASK_ID: avaxAutotaskId
	} = process.env

	if (!mumbaiAutotaskId) throw new Error(`Missing autotask id`)
	await uploadCode(mumbaiAutotaskId, apiKey, apiSecret)
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
