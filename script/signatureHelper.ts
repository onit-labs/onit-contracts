const { createHash } = require('crypto')
import * as elliptic from 'elliptic'

const EC = elliptic.ec
const ec = new EC('p256')

// Setup test data based off last userOp
const rawAuthenticatorData = 'FYRIL996TQt+udRc+DUojLWeVbgkn/81bjO+iOzFRtEdAAAAAA=='

export async function formatMessageFromAuthDataAndClientJson(userOpHash) {
	// Get authentaicator and client json data into buffer form
	const authenticatorDataBuffer = Buffer.from(rawAuthenticatorData, 'base64')

	const clientDataJsonBytes = Buffer.from(
		`{"type":"webauthn.get","challenge":"${userOpHash}","origin":"https://development.forumdaos.com"}',
		'utf8`
	)

	// Hash client data
	const hashedClientDataJson = createHash('SHA256').update(clientDataJsonBytes).digest('hex')

	// Build message used for sig
	const signatureBase = Buffer.concat([
		new Uint8Array(authenticatorDataBuffer),
		Buffer.from(hashedClientDataJson, 'hex')
	])

	const messageData = createHash('SHA256').update(signatureBase).digest('hex')

	return messageData
}

function generateKeyPair() {
	const key = ec.genKeyPair()

	const publicKey = key.getPublic()

	const x = publicKey.getX()
	const y = publicKey.getY()

	return [x.toString(), y.toString()]
}

/**
 * @notice Signs a message for a given public key
 * @param inputs : message to sign, and public key x and y
 * @returns signature
 */
function signMessage(inputs: string[]) {
	const [message, x, y] = inputs

	const key = ec.keyFromPrivate([x, y])
	const signature = key.sign(formatMessageFromAuthDataAndClientJson(message))

	return [signature.r.toString(), signature.s.toString()]
}

function run(test, inputs) {
	console.log('test', test[0])

	switch (test[0]) {
		case '1':
			generateKeyPair()
			break
		case '2':
			signMessage(inputs)
			break
	}
}

run(process.argv.slice(2), process.argv)
