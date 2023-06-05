import { Feeds__factory } from 'typechain'
import { Signer } from 'ethers'
import basicFeeds from './data'
import parseError from './parseError'

export default async function (contractAddress: string, signer: Signer) {
  try {
    console.log('Adding basic feeds')
    const contract = Feeds__factory.connect(contractAddress, signer)
    for (const feed of basicFeeds) {
      const tx = await contract.addFeed(feed)
      await tx.wait()
    }
    console.log('Successfully added feeds!')
  } catch (e) {
    console.error('Error while adding feeds: ', parseError(e))
    console.error(
      'Please add feeds manually for this address: ',
      contractAddress
    )
  }
}
