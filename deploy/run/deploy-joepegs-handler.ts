import { COMMISSION_BASED_FUNCTIONS, COMMISSION_FREE_FUNCTIONS, ZERO_ADDRESS } from '../../config'

import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const deterministicDeployment = await deterministic('JoepegsProposalHandler', {
		salt: '0x0000000000000000000000000000000000000000000000000000000000000003',
		contract: 'JoepegsProposalHandler',
		from: deployer,
		args: [200, COMMISSION_FREE_FUNCTIONS, COMMISSION_BASED_FUNCTIONS],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_JoepegsProposalHandler' // id required to prevent reexecution
func.tags = ['JoepegsProposalHandler', 'Forum']
