import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const ForumGroup = await hre.ethers.getContract('ForumGroupV2')
	const CommissionManager = await hre.ethers.getContract('CommissionManager')

	const deterministicDeployment = await deterministic('ForumFactoryV2', {
		contract: 'ForumFactoryV2',
		from: deployer,
		args: [deployer, ForumGroup.address, CommissionManager.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_ForumFactoryV2' // id required to prevent reexecution
func.tags = ['ForumFactoryV2', 'Multisig', 'Forum']
func.dependencies = ['ForumGroupV2', 'CommissionManager']
