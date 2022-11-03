import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const ForumGroup = await hre.ethers.getContract('ForumGroup')
	const ExecutionManager = await hre.ethers.getContract('ExecutionManager')
	const ShieldManager = await hre.ethers.getContract('ShieldManager')

	const deterministicDeployment = await deterministic('ForumFactory', {
		contract: 'ForumFactory',
		from: deployer,
		args: [deployer, ForumGroup.address, ExecutionManager.address, ShieldManager.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_Forum' // id required to prevent reexecution
func.tags = ['ForumFactory', 'Multisig', 'Forum']
