import { ethers, run, upgrades } from 'hardhat'
import getScannerUrl from './getScannerUrl'
import parseError from './parseError'

export default async function ({
  proxyAddress,
  contractName,
  chainName,
}: {
  proxyAddress: string
  contractName: string
  chainName: string
}) {
  console.log('---------------')
  console.log(`Upgrading ${contractName} at proxy address ${proxyAddress}...`)
  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.upgradeProxy(proxyAddress, contractFactory)

  console.log('Wait for 15 seconds to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 15 * 1000))

  const contractImplementationAddress =
    await upgrades.erc1967.getImplementationAddress(contract.address)
  const contractAdminAddress = await upgrades.erc1967.getAdminAddress(
    contract.address
  )

  console.log(`${contractName} Upgraded`)
  console.log(`${contractName} Proxy address: `, contract.address)
  console.log(
    `${contractName} Implementation address: `,
    contractImplementationAddress
  )
  console.log(`${contractName} Admin address: `, contractAdminAddress)

  console.log(`Verifying ${contractName} Implementation contract`)
  try {
    await run('verify:verify', { address: contractImplementationAddress })
  } catch (err) {
    console.error('Error verifying contract on Etherscan:', parseError(err))
  }

  // Print out the information
  console.log(`${contractName} upgraded, initialized and verified!`)
  console.log(`${contractName} contract address (proxy): `, contract.address)
  console.log(
    `${contractName} scanner URL:`,
    getScannerUrl(chainName, contract.address)
  )
  console.log('---------------')

  return contract
}
