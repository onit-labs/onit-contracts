import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const ForumGroup = await hre.ethers.getContract('ForumGroup')
	const CommissionManager = await hre.ethers.getContract('CommissionManager')

	const deterministicDeployment = await deterministic('ForumFactory', {
		contract: 'ForumFactory',
		from: deployer,
		args: [deployer],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	// Set the ForumGroup and CommissionManager addresses
	const factoryDeploy = await deterministicDeployment.deploy()
	const factory = await hre.ethers.getContractAt('ForumFactory', factoryDeploy.address)

	await factory.setForumMaster(ForumGroup.address)
	await factory.setCommissionManager(CommissionManager.address)
}

export default func
func.id = 'deploy_ForumFactory' // id required to prevent reexecution
func.tags = ['ForumFactory', 'Multisig', 'Forum']
func.dependencies = ['ForumGroup', 'CommissionManager']
