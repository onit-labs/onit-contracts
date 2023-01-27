import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { GnosisContracts } from '../helpers'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const ForumSafeModule = await hre.ethers.getContract('ForumSafeModule')
	const ForumFundraiseExtension = await hre.ethers.getContract('ForumFundraiseExtension')
	const ForumWithdrawalExtension = await hre.ethers.getContract('ForumWithdrawalExtension')
	const pfpSetter = await hre.ethers.getContract('PfpSetter')

	const deterministicDeployment = await deterministic('ForumSafeFactory', {
		contract: 'ForumSafeFactory',
		from: deployer,
		args: [
			ForumSafeModule.address,
			GnosisContracts.gnosisSingleton,
			GnosisContracts.gnosisFallback,
			GnosisContracts.gnosisMultisend,
			GnosisContracts.gnosisSafeProxyFactory,
			ForumFundraiseExtension.address,
			ForumWithdrawalExtension.address,
			pfpSetter.address
		],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}

export default func
func.id = 'deploy_ForumSafeFactory' // id required to prevent reexecution
func.tags = ['ForumSafeFactory', 'Safe', 'Forum']
func.dependencies = [
	'ForumSafeModule',
	'ForumFundraiseExtension',
	'ForumWithdrawalExtension',
	'PfpSetter'
]
