import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const WithdrawalTransferManager = await hre.ethers.getContract('WithdrawalTransferManager')

	const deterministicDeployment = await deterministic('ForumWithdrawal', {
		contract: 'ForumWithdrawal',
		from: deployer,
		args: [WithdrawalTransferManager.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_ForumWithdrawal' // id required to prevent reexecution
func.tags = ['ForumWithdrawal', 'Forum', 'Extension']
func.dependencies = ['WithdrawalTransferManager']
