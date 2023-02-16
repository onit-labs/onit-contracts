const { createHash } = require('crypto')
import * as elliptic from 'elliptic'

const EC = elliptic.ec
const ec = new EC('p256')

/**
 * Convert a UTF-8 string back into bytes
 */
export function fromUTF8String(utf8String: string): Uint8Array {
	const encoder = new globalThis.TextEncoder()
	return encoder.encode(utf8String)
}

// Setup test data based off last userOp
const rawAuthenticatorData = 'FYRIL996TQt+udRc+DUojLWeVbgkn/81bjO+iOzFRtEdAAAAAA=='

// Test data from signed message returns
const accountMessageSigs = {
	test1: {
		message: 0xf2424746de28d3e593fb6af9c8dff6d24de434350366e60312aacfe79dae94a8,
		publicKey: {
			x: 'd3c6949ab309ff80296ffb17cd2a5298ec23ad7f1fda03ca70f12353987303de',
			y: '42c164839f37f10fb2e6e5649c046a473a8d4db61d0602433fe32484d1c2d8d3'
		},
		sig: {
			r: '535b670719b8510bcf71a9713c23f0dadff3ec73bca56e472d01976ca16d88b7',
			s: 'b4b64109a6a35302be6297bc0c7444e117c6e0185caa71d11486ad04f33f8ddd'
		}
	},
	test2: {
		message: '331e04c82b160721ff30b8b6cd656a11331620b83e938ddca3eb29cf71bbc355', //0x75f6954424c5ac191d504086214ca53c4d0d199fcfd47da90364eab2aa98a31d,
		publicKey: {
			x: '7088c8f47cbe4745dc5e9e44302dcf1a528766b48470dea245076b8e91ebe2c5',
			y: 'e498cf1f4f1ed27c1db3e78d389673bb40f26fc7d2d9e3ae8ca247ff3ba6c570'
		},
		sig: {
			r: '0fb0aa68dce6f1517cfb4cad4659a3ea403edc9f31994dd6bd2e1945df0f11bb',
			s: '83479be56839e8c3e089613a02dd09f1a035751db0cb4fcf728bf94a231e0285'
		}
	}
}

export async function getMessageFromAuthDataAndClientJson() {
	// Get authentaicator and client json data into buffer form
	const authenticatorDataBuffer = Buffer.from(rawAuthenticatorData, 'base64')
	const authenticatorDataBufferHex = Buffer.from(rawAuthenticatorData, 'base64').toString('hex')

	const clientDataJsonBytes = Buffer.from(
		'{"type":"webauthn.get","challenge":"dfaVRCTFrBkdUECGIUylPE0NGZ_P1H2pA2TqsqqYox0","origin":"https://development.forumdaos.com"}',
		'utf8'
	)

	// Hash client data
	const hashedClientDataJson = createHash('SHA256').update(clientDataJsonBytes).digest('hex')

	console.log({
		clientData: {
			clientDataJsonBytes,
			hashedClientDataJson
		},
		authData: {
			authenticatorDataBuffer,
			authenticatorDataBufferHex
		}
	})

	// Build message used for sig
	const signatureBase = Buffer.concat([
		new Uint8Array(authenticatorDataBuffer),
		Buffer.from(hashedClientDataJson, 'hex')
	])

	const messageData = createHash('SHA256').update(signatureBase).digest('hex')
	const messageDataBase64 = createHash('SHA256').update(signatureBase).digest('base64')

	console.log({
		authenticatorDataBuffer,
		signatureBase: {
			signatureBase,
			signatureBaseHex: Buffer.from(signatureBase).toString('hex')
		},
		messageData,
		messageDataBase64
	})

	return messageData
}

function testElliptic() {
	//const messageData = Buffer.from('0x1234', 'hex')
	const messageData = accountMessageSigs.test2.message
	const messageBuff = Buffer.from(messageData, 'hex')
	console.log({ messageData, messageBuff })

	// CHECK WITH PASSKEY
	var key = ec.keyFromPublic(accountMessageSigs.test2.publicKey, 'hex')

	// Verify signature
	console.log('verify passkey sig', key.verify(messageBuff, accountMessageSigs.test2.sig))
}

function run(test) {
	console.log('test', test[0])

	switch (test[0]) {
		case '1':
			getMessageFromAuthDataAndClientJson()
			break
		case '2':
			testElliptic()
			break
	}
}

run(process.argv.slice(2))
