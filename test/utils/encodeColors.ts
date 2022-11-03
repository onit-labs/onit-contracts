import { BigNumberish } from 'ethers'
import { ethers } from 'hardhat'

export default function encodeColors(
	colors: number[] | BigNumberish[]
): [BigNumberish, BigNumberish, BigNumberish, BigNumberish] {
	const colorArray: [BigNumberish, BigNumberish, BigNumberish, BigNumberish] = [0, 0, 0, 0]

	colors.forEach((color, index) => {
		colorArray[index] = color
	})

	return colorArray
}
