import { ContractFactory } from 'ethers'
import { ethers as hardhatEthers } from 'hardhat'

import web3Utils = require('web3-utils')

export const SALT = '0x0000000000000000000000000000000000000000000000000000000000000000'

export const SINGLETON_FACTORY_ADDRESS = '0xce0042B868300000d44A59004Da54A005ffdcf9f'

export const SINGLETON_FACTORY_INTERFACE = new hardhatEthers.utils.Interface([
	'function deploy(bytes memory _initCode, bytes32 _salt)'
])

// ! These should be checked
export const GnosisContracts = {
	gnosisSingleton: '0xd9Db270c1B5E3Bd161E8c8503c55cEABeE709552',
	gnosisMultisend: '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761',
	gnosisFallback: '0xf48f2B2d2a534e402487b3ee7C18c33Aec0Fe5e4',
	gnosisSafeProxyFactory: '0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2'
}

export type DeployedSVGs = {
	[contractName: string]: string
}

export type DeployedContracts = {
	[svgType: string]: DeployedSVGs
}

export type DeployedContractReceipt = {
	contractName: string
	address: string
	transactionHash?: string
}

export type DeployStatus = {
	deployed: boolean
	contractFactory: ContractFactory
	receipt: DeployedContractReceipt
}

export function constructDeploymentArchive(
	svgType: string,
	receipt: DeployedContractReceipt,
	deployedContracts: DeployedContracts
): DeployedContracts {
	svgType = `${svgType.toLowerCase()}s`
	deployedContracts[svgType][lowercaseFirst(receipt.contractName)] = receipt.address
	return deployedContracts
}

export function computeAddress(initcode: string): string {
	const codeHash = web3Utils.soliditySha3({ t: 'bytes', v: initcode })
	if (!codeHash) {
		throw 'No codehash'
	}
	const addressAsBytes32 = web3Utils.soliditySha3(
		{ t: 'uint8', v: 255 }, // 0xff
		{ t: 'address', v: SINGLETON_FACTORY_ADDRESS },
		{ t: 'bytes32', v: SALT },
		{ t: 'bytes32', v: codeHash }
	)
	return `0x${addressAsBytes32?.slice(26, 66)}`
}

export async function isDeployed(
	factoryName: string
	// hardhatEthers: typeof ethers
): Promise<DeployStatus> {
	const contractFactory = await hardhatEthers.getContractFactory(factoryName)
	const bytecode = contractFactory.bytecode
	const computedAddress = computeAddress(bytecode)
	const deployedCode = await hardhatEthers.provider.getCode(computedAddress)
	let deployed = false

	if (deployedCode.length > 2) {
		console.log(`${factoryName} already deployed at ${computedAddress}`)
		deployed = true
	}

	return {
		deployed,
		contractFactory: contractFactory,
		receipt: { contractName: factoryName, address: computedAddress }
	}
}

export function formatJSONpath(JSON_PATH: string, network: string): string {
	const split = JSON_PATH.split('.')

	return split[0] + '_' + network + '.' + split[1]
}

function lowercaseFirst(str: string): string {
	return str[0].toLowerCase() + str.slice(1)
}
