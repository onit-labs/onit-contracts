import { handler } from '../../src/relay-user-op'

require('dotenv').config({ path: '.env' })

// Run autotask code locally using the Relayer API key and secret
if (require.main === module) {
	const { MUMBAI_USER_OP_RELAY_API: apiKey, MUMBAI_USER_OP_RELAY_SECRET: apiSecret } = process.env

	const body = require('./data/relay-user-op-request.json')

	// Hardcode entryPoint addresses for testing
	handler({
		apiKey,
		apiSecret,
		request: { body: body },
		secrets: {
			mumbai_entry_point_address: '0x119df1582e0dd7334595b8280180f336c959f3bb',
			polygon_entry_point_address: '0x119df1582e0dd7334595b8280180f336c959f3bb'
		}
	})
		.then(() => process.exit(0))
		.catch((error) => {
			console.error(error)
			process.exit(1)
		})
}
