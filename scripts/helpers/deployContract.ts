import { ethers, run, upgrades } from 'hardhat'
import { utils } from 'ethers'
import getScannerUrl from './getScannerUrl'
import parseError from './parseError'

export default async function ({
  constructorArguments,
  contractName,
  chainName,
  initializer = 'initialize',
}: {
  constructorArguments: string[]
  contractName: string
  chainName: string
  initializer?: string
}) {
  console.log('---------------')
  console.log(
    `Deploying ${contractName} with arguments ${constructorArguments}...`
  )
  const contractFactory = await ethers.getContractFactory(contractName)
  const contract = await upgrades.deployProxy(
    contractFactory,
    constructorArguments,
    { initializer }
  )
  console.log(
    'Deploy tx gas price:',
    utils.formatEther(contract.deployTransaction.gasPrice || 0)
  )
  console.log(
    'Deploy tx gas limit:',
    utils.formatEther(contract.deployTransaction.gasLimit)
  )
  await contract.deployed()

  const contractImplementationAddress =
    await upgrades.erc1967.getImplementationAddress(contract.address)
  const contractAdminAddress = await upgrades.erc1967.getAdminAddress(
    contract.address
  )

  console.log(`${contractName} Proxy address: `, contract.address)
  console.log(
    `${contractName} Implementation address: `,
    contractImplementationAddress
  )
  console.log(`${contractName} Admin address: `, contractAdminAddress)

  console.log('Wait for 1 minute to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 15 * 1000))

  console.log(`Verifying ${contractName} contract`)
  try {
    await run('verify:verify', { address: contractImplementationAddress })
  } catch (err) {
    console.error('Error verifying contract on Etherscan:', parseError(err))
  }

  // Print out the information
  console.log(`${contractName} deployed and verified!`)
  console.log(`${contractName} contract address: `, contract.address)
  console.log(
    `${contractName} scanner URL:`,
    getScannerUrl(chainName, contract.address)
  )
  console.log('---------------')

  return contract
}
