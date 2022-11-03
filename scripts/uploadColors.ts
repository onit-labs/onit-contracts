import { colors } from './colors'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { ethers as hardhatEthers } from 'hardhat'

const hre = require('hardhat')
const fs = require('fs')

const COLOR_COUNT = 1565
const BATCH_SIZE = 100

export async function addColors() {
	const networkName = hre.network.name
	const FieldGeneratorDeployment = `deployments/${networkName}/FieldGenerator.json`

	const [deployer] = await hardhatEthers.getSigners()

	console.log(`Adding colors to FieldGenerator on network ${networkName}`)

	for (let i = 0; i < COLOR_COUNT; i += BATCH_SIZE) {
		const deployingContracts: Promise<any>[] = []
		const batchColor: number[] = []
		const batchTitle: string[] = []

		for (let j = i; j < i + BATCH_SIZE; j++) {
			if (j < COLOR_COUNT) {
				batchColor.push(parseInt(colors[j][0], 16))
				batchTitle.push(colors[j][1])
			}
		}
		console.log({ batchColor })
		console.log({ batchTitle })

		let nonce = await hardhatEthers.provider.getTransactionCount(deployer.address)

		deployingContracts.push(
			addColorsToContract(
				'FieldGenerator',
				nonce++,
				deployer,
				batchColor,
				batchTitle,
				FieldGeneratorDeployment
			)
		)
		await Promise.all(deployingContracts)
	}
	console.log('Color Uploads Completed')
}

async function addColorsToContract(
	factoryName: string,
	nonce: number,
	deployer: SignerWithAddress,
	colors: number[],
	titles: string[],
	FieldGeneratorDeployment: string
): Promise<any> {
	console.log(`Adding colors to ${factoryName}...`)
	console.log('nonce', nonce)

	let deploymentArchive = JSON.parse(
		fs.readFileSync(FieldGeneratorDeployment, { encoding: 'utf8' })
	)

	const fieldGen = new hardhatEthers.Contract(
		deploymentArchive.address,
		deploymentArchive.abi,
		deployer
	)
	const transaction = await fieldGen.addColors(colors, titles, {
		gasLimit: 8_000_000,
		nonce,
		maxFeePerGas: '35000000000',
		maxPriorityFeePerGas: '1000000000'
	})

	console.log(transaction.hash)
	const txReceipt = await transaction.wait()

	console.log(`successfully added color batch!\n\thash:\t\t${txReceipt.transactionHash}\n`)
	return {
		contractName: factoryName,
		transactionHash: ''
	}
}

addColors()
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
		process.exit(1)
	})
