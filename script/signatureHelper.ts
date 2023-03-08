const { createHash } = require('crypto')
import { AbiCoder } from '@ethersproject/abi'
import * as elliptic from 'elliptic'

const EC = elliptic.ec
const ec = new EC('p256')

// Setup test data based off last userOp
const rawAuthenticatorData = 'FYRIL996TQt+udRc+DUojLWeVbgkn/81bjO+iOzFRtEdAAAAAA=='

async function formatMessageFromAuthDataAndClientJson(userOpHash) {
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

// Ffi expects encoded outputs
function encodeOutput(types: string[], values: any[]) {
	const encoder = new AbiCoder()
	return encoder.encode(types, values)
}

function generateKeyPair(inputs: string[]) {
	const [salt] = inputs

	const key = ec.genKeyPair({ nonce: salt })

	const publicKey = key.getPublic()

	const x = publicKey.getX()
	const y = publicKey.getY()

	const encoder = new AbiCoder()
	console.log(encoder.encode(['uint256[2]'], [[x.toString(), y.toString()]]))
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

	console.log(encodeOutput(['uint256[2]'], [[signature.r.toString(), signature.s.toString()]]))
}

function run(inputs) {
	switch (inputs[0]) {
		case 'gen':
			return generateKeyPair(inputs)
			break
		case 'sign':
			signMessage(inputs)
			break
	}
}

run(process.argv.slice(2))
