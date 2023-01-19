import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const WithdrawalTransferManager = await hre.ethers.getContract('WithdrawalTransferManagerV2')

	const deterministicDeployment = await deterministic('ForumWithdrawalExtension', {
		contract: 'ForumWithdrawalExtension',
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
func.id = 'deploy_ForumWithdrawalExtension' // id required to prevent reexecution
func.tags = ['ForumWithdrawalExtension', 'Forum', 'Extension']
func.dependencies = ['WithdrawalTransferManagerV2']
