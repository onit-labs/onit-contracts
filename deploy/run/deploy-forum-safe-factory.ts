import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { GnosisContracts } from '../helpers'

// ! check this - do we want module in deploy args?
// changes to module code would effect deployed address

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const ForumSafeModule = await hre.ethers.getContract('ForumSafeModule')

	const deterministicDeployment = await deterministic('ForumSafeFactory', {
		contract: 'ForumSafeFactory',
		from: deployer,
		args: [
			deployer,
			ForumSafeModule.address,
			GnosisContracts.gnosisSingleton,
			GnosisContracts.gnosisFallback,
			GnosisContracts.gnosisMultisend,
			GnosisContracts.gnosisSafeProxyFactory
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
func.dependencies = ['ForumSafeModule']
