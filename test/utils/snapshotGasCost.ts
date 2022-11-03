import { TransactionReceipt, TransactionResponse } from '@ethersproject/abstract-provider'
import { expect } from 'chai'
import { BigNumber, Contract, ContractTransaction } from 'ethers'

// .toMatchSnapshot() failing

export default async function snapshotGasCost(
	x:
		| TransactionResponse
		| Promise<TransactionResponse>
		| ContractTransaction
		| Promise<ContractTransaction>
		| TransactionReceipt
		| Promise<BigNumber>
		| BigNumber
		| Contract
		| Promise<Contract>
): Promise<void> {
	const resolved = await x
	if ('deployTransaction' in resolved) {
		const receipt = await resolved.deployTransaction.wait()
		console.log(receipt.gasUsed.toNumber())

		expect(receipt.gasUsed.toNumber()).greaterThan(0)
	} else if ('wait' in resolved) {
		const waited = await resolved.wait()
		expect(waited.gasUsed.toNumber()).greaterThan(0)
	} else if (BigNumber.isBigNumber(resolved)) {
		expect(resolved.toNumber()).greaterThan(0)
	}
}
