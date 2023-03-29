import { handler } from '../../src/relay-account-deploy'

require('dotenv').config({ path: '.env' })

// TODO Condense all these call scripts into one

// Run autotask code locally using the Relayer API key and secret
if (require.main === module) {
	const {
		MUMBAI_DEPLOY_ACCOUNT_RELAY_API: apiKey,
		MUMBAI_DEPLOY_ACCOUNT_RELAY_SECRET: apiSecret
	} = process.env

	const testPayloads = JSON.parse(
		require('fs')
			.readFileSync('services/oz-defender/autotasks/test/deploy-account-request.json')
			.toString()
	)

	// 0 for individual, 1 for group
	const body = testPayloads[1]

	// Hardcode factory addresses for testing
	handler({
		apiKey,
		apiSecret,
		request: { body: body },
		secrets: {
			groupAccountFactoryAddress: '0x299A19b63502b63335D1ec20c9088E16Eb122071',
			individualAccountFactoryAddress: '0x3A004B31aF5B8337681DA2DD8c2C9073b5C4100d'
		}
	})
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error)
			process.exit(1)
		})
}
