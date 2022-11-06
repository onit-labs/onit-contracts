import { ZERO_ADDRESS } from '../../config'

import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const ShieldManager = await hre.ethers.getContract('ShieldManager')
	const ForumFactory = await hre.ethers.getContract('ForumFactory')

	const deterministicDeployment = await deterministic('PfpStakerV2', {
		contract: 'PfpStakerV2',
		from: deployer,
		args: [deployer, ShieldManager.address, ForumFactory.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_PFP_StakerV2' // id required to prevent reexecution
func.tags = ['PfpStakerV2', 'Extensions', 'Forum']
