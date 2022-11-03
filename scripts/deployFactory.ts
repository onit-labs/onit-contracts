import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

async function main() {
	// Hardhat always runs the compile task when running scripts with its command
	// line interface.

	const [deployer] = await ethers.getSigners()

	console.log('Deploying contracts with the account:', deployer.address)

	console.log('Account balance:', (await deployer.getBalance()).toString())

	const GenerateMultisig = await ethers.getContractFactory('GenerateMultisig')
	const factoryContract = await GenerateMultisig.deploy()

	await factoryContract.deployed()

	console.log('multiSigContract deployed to:', factoryContract.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error)
	process.exitCode = 1
})
