import { BWLPaymaster__factory } from '@big-whale-labs/gsn-paymaster-contract'
import { GSN_PAYMASTER_CONTRACT } from '../../hardhat.config'
import { Signer } from 'ethers'
import parseError from './parseError'

export default async function (contractAddress: string, signer: Signer) {
  try {
    console.log(
      `Adding ${contractAddress} to ${GSN_PAYMASTER_CONTRACT} paymaster targets`
    )
    const paymaster = BWLPaymaster__factory.connect(
      GSN_PAYMASTER_CONTRACT,
      signer
    )
    const tx = await paymaster.addTargets([contractAddress])
    await tx.wait()
    console.log('Successfully added to paymaster targets')
  } catch (e) {
    console.error('Error adding contract to paymaster targets: ', parseError(e))
    console.error(
      'Please add contract ',
      contractAddress,
      ' to paymaster ',
      GSN_PAYMASTER_CONTRACT,
      ' manually'
    )
  }
}
