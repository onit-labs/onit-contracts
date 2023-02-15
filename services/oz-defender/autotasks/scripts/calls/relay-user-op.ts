import { handler } from '../../src/relay-user-op'

require('dotenv').config({ path: '.env' })

// Run autotask code locally using the Relayer API key and secret
if (require.main === module) {
	const { AVAX_OPENSEA_RELAY_API: apiKey, AVAX_OPENSEA_RELAY_SECRET: apiSecret } = process.env

	const payload = require('fs').readFileSync('../../testing/relay-opensea-request.json')

	// 0 = mint pass
	// 1 = toggle WL
	// 2 = build shield for owner
	// 3 = batch and drop item
	const body = JSON.parse(payload.toString())
	console.log(body)

	handler({
		apiKey,
		apiSecret,
		request: { body: body }
	})
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error)
			process.exit(1)
		})
}
