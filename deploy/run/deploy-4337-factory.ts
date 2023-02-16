import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { ZERO_ADDRESS } from '../../config'
import { GnosisContracts } from '../helpers'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const EIP4337Account = await hre.ethers.getContract('EIP4337Account')
	//const EntryPoint = await hre.ethers.getContract('EntryPoint')

	const deterministicDeployment = await deterministic('EIP4337AccountFactory', {
		contract: 'EIP4337AccountFactory',
		from: deployer,
		args: [EIP4337Account.address, ZERO_ADDRESS, GnosisContracts.gnosisFallback],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}

export default func
func.id = 'deploy_EIP4337AccountFactory' // id required to prevent reexecution
func.tags = ['EIP4337AccountFactory', 'Forum']
func.dependencies = ['EIP4337Account']
