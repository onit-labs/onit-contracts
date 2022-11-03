import { ACCESS_PASS_METADATA } from '../../config'

import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	// const AccessPassStore = await hre.ethers.getContract('AccessPassStore')

	const deterministicDeployment = await deterministic('AccessManager', {
		contract: 'AccessManager',
		from: deployer,
		args: [deployer, 'AccessManager', 'ACCESS', ACCESS_PASS_METADATA],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('35000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('10000000000')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_AccessManager' // id required to prevent reexecution
func.tags = ['AccessManager', 'Access']
