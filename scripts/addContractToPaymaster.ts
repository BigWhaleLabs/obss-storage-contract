import { BWLPaymaster__factory } from '@big-whale-labs/gsn-paymaster-contract'
import { GSN_PAYMASTER_CONTRACT } from '../hardhat.config'
import { Signer } from 'ethers'

export default async function addContractToPaymaster(
  contractAddress: string,
  signerOrProvider: Signer
) {
  console.log(
    `Adding ${contractAddress} to ${GSN_PAYMASTER_CONTRACT} paymaster targets`
  )
  const paymaster = BWLPaymaster__factory.connect(
    GSN_PAYMASTER_CONTRACT,
    signerOrProvider
  )
  const tx = await paymaster.addTargets([contractAddress])
  await tx.wait()
  console.log('Successfully added to paymaster targets')
}
