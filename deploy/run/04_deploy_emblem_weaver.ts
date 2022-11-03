import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
	const { deployer } = await hre.getNamedAccounts()
	const { deterministic } = hre.deployments
	const FieldGenerator = await hre.ethers.getContract('FieldGenerator')
	const HardwareGenerator = await hre.ethers.getContract('HardwareGenerator')
	const FrameGenerator = await hre.ethers.getContract('FrameGenerator')

	const deterministicDeployment = await deterministic('EmblemWeaver', {
		contract: 'EmblemWeaver',
		from: deployer,
		args: [FieldGenerator.address, HardwareGenerator.address, FrameGenerator.address],
		log: true,
		autoMine: true, // speed up deployment on local network (ganache, hardhat), no effect on live networks
		maxFeePerGas: hre.ethers.BigNumber.from('95000000000'),
		maxPriorityFeePerGas: hre.ethers.BigNumber.from('1')
	})

	await deterministicDeployment.deploy()
}
export default func
func.id = 'deploy_EmblemWeaver' // id required to prevent reexecution
func.tags = ['EmblemWeaver', 'Shields']
