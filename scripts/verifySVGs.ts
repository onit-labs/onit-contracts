import { HardhatRuntimeEnvironment } from 'hardhat/types'
import EtherscanResponse from '@nomiclabs/hardhat-etherscan/src/etherscan/EtherscanService'
import { formatJSONpath } from '../deploy/helpers'

const hre = require('hardhat')
const fs = require('fs')

const JSON_PATH = 'deploy/deployedSVGs.json'

const func = async function (hre: HardhatRuntimeEnvironment) {
	const networkName = await hre.network.name

	const deploymentArchive = JSON.parse(
		fs.readFileSync(formatJSONpath(JSON_PATH, networkName), { encoding: 'utf8' })
	)

	console.log(`Verifing SVG Contracts on ${networkName}....`)

	await batchVerifySVGs('fields', 24, deploymentArchive)
	await batchVerifySVGs('hardwares', 38, deploymentArchive)
	await batchVerifySVGs('frames', 2, deploymentArchive)
}

async function batchVerifySVGs(svgType: string, maxContract: number, deploymentArchive: object) {
	for (let i = 1; i <= maxContract; i++) {
		await verifyContract(
			deploymentArchive[svgType][`${svgType.substring(0, svgType.length - 1)}SVGs${i}`]
		)
			.then((r) => {
				console.log('success: ', r.message)
			})
			.catch((e) => {
				console.log('error: ', e.message)
			})
	}
}
// TODO check return of task here.. EtherscanResponse is not being returned as expected
async function verifyContract(contract): Promise<EtherscanResponse> {
	const res: EtherscanResponse = await hre.run(`verify:verify`, {
		address: contract
	})
	console.log({ res })
	return res
}

func(hre)
