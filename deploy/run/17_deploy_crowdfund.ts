import { ZERO_ADDRESS } from '../../config'

import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const ForumFactory = await hre.ethers.getContract('ForumFactoryV2')
	const CrowdfundExecutionManager = await hre.ethers.getContract('CrowdfundExecutionManager')

	const deterministicDeployment = await deterministic('ForumCrowdfund', {
		contract: 'ForumCrowdfund',
		from: deployer,
		args: [ForumFactory.address, CrowdfundExecutionManager.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_Crowdfund' // id required to prevent reexecution
func.tags = ['ForumCrowdfund', 'Forum']
