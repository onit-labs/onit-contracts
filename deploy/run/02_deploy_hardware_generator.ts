import { formatJSONpath } from '../helpers'

import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

import fs = require('fs')

const JSON_PATH = 'deploy/deployedSVGs.json'
let JSON_PATH_BY_NETWORK: string

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployments, getNamedAccounts, network } = hre
	const { deterministic } = deployments

	const { deployer } = await getNamedAccounts()

	JSON_PATH_BY_NETWORK = formatJSONpath(JSON_PATH, network.name)

	const svgDeploymentArchive = JSON.parse(
		fs.readFileSync(JSON_PATH_BY_NETWORK, { encoding: 'utf8' })
	)

	const deterministicDeployment = await deterministic('HardwareGenerator', {
		contract: 'HardwareGenerator',
		from: deployer,
		args: [svgDeploymentArchive.hardwares],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('110000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_HardwareGenerator' // id required to prevent reexecution
func.tags = ['HardwareGenerator', 'Shields']
