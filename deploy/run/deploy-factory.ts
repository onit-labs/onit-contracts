import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ForumFactory, ForumGroup } from '../../typechain'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

<<<<<<< HEAD:deploy/run/deploy-factory.ts
	// const ForumGroup = await hre.ethers.getContract('ForumGroup')
	// const CommissionManager = await hre.ethers.getContract('CommissionManager')
=======
	const ForumGroup = await hre.ethers.getContract('ForumGroup')
	const CommissionManager = await hre.ethers.getContract('CommissionManager')
>>>>>>> main:deploy/run/09_deploy_factory.ts

	const deterministicDeployment = await deterministic('ForumFactory', {
		contract: 'ForumFactory',
		from: deployer,
<<<<<<< HEAD:deploy/run/deploy-factory.ts
		args: [deployer],
=======
		args: [deployer, ForumGroup.address, CommissionManager.address],
>>>>>>> main:deploy/run/09_deploy_factory.ts
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}

export default func
func.id = 'deploy_ForumFactory' // id required to prevent reexecution
func.tags = ['ForumFactory', 'Multisig', 'Forum']
func.dependencies = ['ForumGroup', 'CommissionManager']
