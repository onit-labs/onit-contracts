import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments

	const EmblemWeaver = await hre.ethers.getContract('EmblemWeaver')

	const deterministicDeployment = await deterministic('ShieldManager', {
		contract: 'ShieldManager',
		from: deployer,
		args: [deployer, 'RoundtableShields', 'SHIELDS', EmblemWeaver.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_Shields' // id required to prevent reexecution
func.tags = ['ShieldManager', 'Shields']
