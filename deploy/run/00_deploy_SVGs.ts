import {
	computeAddress,
	constructDeploymentArchive,
	DeployedContractReceipt,
	DeployStatus,
	formatJSONpath,
	isDeployed,
	SALT,
	SINGLETON_FACTORY_ADDRESS,
	SINGLETON_FACTORY_INTERFACE
} from '../helpers'

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { ContractFactory } from 'ethers'
import { ethers as hardhatEthers } from 'hardhat'
import { DeployFunction, DeployResult } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

import fs = require('fs')

const JSON_PATH = 'deploy/deployedSVGs.json'
let JSON_PATH_BY_NETWORK: string

const BATCH_SIZE = 10

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const networkName = await hre.network.name

	const [deployer] = await hardhatEthers.getSigners()

	console.log('Deploying SVGs....')
	console.log({ networkName })

	JSON_PATH_BY_NETWORK = formatJSONpath(JSON_PATH, networkName)

	// setup JSON file if nonexistant
	if (!fs.existsSync(JSON_PATH_BY_NETWORK) || fs.readFileSync(JSON_PATH_BY_NETWORK).length === 0) {
		fs.writeFileSync(
			JSON_PATH_BY_NETWORK,
			JSON.stringify({ fields: {}, hardwares: {}, frames: {} }, null, 2)
		)
	}

	await batchDeploySVGs('Field', 24, deployer, networkName, hre)
	await batchDeploySVGs('Hardware', 38, deployer, networkName, hre)
	await batchDeploySVGs('Frame', 2, deployer, networkName, hre)
}

async function batchDeploySVGs(
	svgType: string,
	maxContract: number,
	deployer: SignerWithAddress,
	networkName: string,
	hre: HardhatRuntimeEnvironment
) {
	for (let i = 1; i <= maxContract; i += BATCH_SIZE) {
		let deploymentArchive = JSON.parse(fs.readFileSync(JSON_PATH_BY_NETWORK, { encoding: 'utf8' }))
		let nonce = await hardhatEthers.provider.getTransactionCount(deployer.address)
		console.log(nonce)
		const checkingDeployStatuses: Promise<DeployStatus>[] = []
		const deployingContracts: Promise<DeployedContractReceipt>[] = []

		for (let j = i; j < i + BATCH_SIZE; j++) {
			if (j <= maxContract) {
				checkingDeployStatuses.push(isDeployed(`${svgType}SVGs${j}`))
			}
		}

		const deployStatuses = await Promise.all(checkingDeployStatuses)

		for (const svgContract of deployStatuses) {
			if (svgContract.deployed === true) {
				deploymentArchive = constructDeploymentArchive(
					svgType,
					svgContract.receipt,
					deploymentArchive
				)
			} else if (svgContract.deployed === false) {
				deployingContracts.push(
					deployContract(
						svgContract.receipt.contractName,
						svgContract.contractFactory,
						nonce++,
						deployer,
						hre
					)
				)
			}
		}

		const receipts = await Promise.all(deployingContracts)

		for (const receipt of receipts) {
			deploymentArchive = constructDeploymentArchive(svgType, receipt, deploymentArchive)
		}
		fs.writeFileSync(JSON_PATH_BY_NETWORK, JSON.stringify(deploymentArchive, null, 2))
	}
}

async function deployContract(
	factoryName: string,
	contractFactory: ContractFactory,
	nonce: number,
	deployer: SignerWithAddress,
	hre: HardhatRuntimeEnvironment
): Promise<DeployedContractReceipt> {
	const { deployments, getNamedAccounts } = hre
	const { deploy, deterministic } = deployments

	console.log(`deploying ${factoryName}...`)
	console.log('nonce', nonce)

	const bytecode = contractFactory.bytecode
	const computedAddress = computeAddress(bytecode)

	const singletonFactoryContract = new hardhatEthers.Contract(
		SINGLETON_FACTORY_ADDRESS,
		SINGLETON_FACTORY_INTERFACE,
		deployer
	)
	const transaction = await singletonFactoryContract.deploy(bytecode, SALT, {
		gasLimit: 6_000_000,
		nonce,
		maxFeePerGas: '35000000000',
		maxPriorityFeePerGas: '25000000000'
	})

	/// ////////
	// The below connects to the correct deployer address and begins the Create2 call to determinsistically
	// create the contract but eventually fails with: Error: legacy pre-eip-155 transactions not supported
	// For now we just deploy contracts normally and keep track of their address on the respective network

	// const transaction = await deterministic(factoryName, {
	// 	from: deployer.address,
	// 	args: [],
	// 	log: true,
	// 	// autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
	// 	maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
	// 	maxPriorityFeePerGas: hre.ethers.BigNumber.from('1'),
	// 	salt: SALT
	// })
	// await transaction.deploy()

	// console.log('tx:')
	// console.log(await transaction.address)
	// const txReceipt = await transaction
	/// ////////

	console.log(transaction.hash)
	const txReceipt = await transaction.wait()

	// console.log(`successfully deployed ${factoryName}!!!\n\taddress:\t${computedAddress}`)
	console.log(
		`successfully deployed ${factoryName}!!!\n\taddress:\t${computedAddress}\n\thash:\t\t${txReceipt.transactionHash}\n`
	)
	return {
		contractName: factoryName,
		address: computedAddress,
		transactionHash: ''
	}
}

export default func
func.id = 'deploy_SVGs' // id required to prevent reexecution
func.tags = ['SVG']
