import EtherscanResponse from '@nomiclabs/hardhat-etherscan/src/etherscan/EtherscanService'

const hre = require('hardhat')
const fs = require('fs')
const path = require('path')

interface verificationData {
	address: string
	args: any[]
}

//	TODO:
// 	The verify task is not returning the EtherscaResponse expected
//	Will check this out later, but for now the script works to verify files and log the results
//

/// @dev The script can be run from the contracts folder with `npx ts-node verifyDeployments.ts`
/// @dev If no arguments are passed, the script will verify all contracts in the deployments folder
/// @dev To pass arguments, run with `npx ts-node verifyDeployments.ts ContractA.json ContractB.json`

export async function verifyDeployments(selectedFiles: string[]) {
	const networkName = hre.network.name
	const deploymentsArchive = `deployments/${networkName}`

	console.log(`Verifing contracts from ${deploymentsArchive} on network ${networkName}`)

	const contracts = await gatherVerificationData(deploymentsArchive, selectedFiles)
	console.log({ gatheredContracts: contracts })

	for (const eachContract of contracts) {
		console.log('verifying contract at: ', eachContract.address)
		await verifyContract(eachContract)
			.then((r) => {
				console.log('success: ', r)
			})
			.catch((e) => {
				console.log('error: ', e)
			})
	}

	console.log('Contract Verifications Completed')
}

async function gatherVerificationData(
	deploymentsArchive: string,
	selectedFiles: string[]
): Promise<Array<verificationData>> {
	const contractBatchData: Array<verificationData> = []
	const contractFilenames = await fs.promises.readdir(deploymentsArchive)

	// If no files are passed, verify all contracts in the deployments folder
	const filteredFiles =
		selectedFiles.length != 0
			? selectedFiles.map((name) => {
					return `${name}.json`
			  })
			: contractFilenames

	// For all .json files in the deployments folder of the specified network
	for (let file of filteredFiles) {
		if (path.extname(file).toLowerCase() === '.json') {
			let tmpContractData: verificationData
			let tmpConstructorArgs: any[] = []

			const absolutePath = path.join(deploymentsArchive, file)
			const data = await fs.promises.readFile(absolutePath, 'utf8')
			const fileAsJSON = JSON.parse(data)

			// Check each of the constructor args from the deployment JSON
			for (const arg of fileAsJSON.args) {
				// If the arg param is an object, convert to an array
				if (typeof arg === 'object' && !Array.isArray(arg) && arg !== null) {
					const result = Object.keys(arg).map((key) => arg[key])
					console.log({ result })
					tmpConstructorArgs.push(result)

					// If not it is fine to push as a string
				} else {
					tmpConstructorArgs.push(arg)
				}
			}
			tmpContractData = { address: fileAsJSON.address, args: tmpConstructorArgs }

			contractBatchData.push(tmpContractData)
		}
	}
	return contractBatchData
}

async function verifyContract(contract: verificationData): Promise<EtherscanResponse> {
	const res: EtherscanResponse = await hre.run(`verify:verify`, {
		address: contract.address,
		constructorArguments: contract.args
	})
	return res
}

verifyDeployments(process.argv.slice(2))
	.then(() => process.exit(0))
	.catch((error) => {
		console.error(error)
	})
