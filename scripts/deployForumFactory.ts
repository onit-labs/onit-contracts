import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

async function main() {
	// Hardhat always runs the compile task when running scripts with its command
	// line interface.

	const ForumFactory = await ethers.getContractFactory('ForumFactory')
	console.log('made forum factory')

	const forumFactory = await ForumFactory.deploy(
		'0xe5a0752452Ea68f11fBd63F30202Cf69B949959D',
		'0x0d6c2CD1DB599c6f623C27f9EAa4b25B34a5d562'
	)

	await forumFactory.deployed()
	console.log('Factroy deployed to:', forumFactory.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error)
	process.exitCode = 1
})
