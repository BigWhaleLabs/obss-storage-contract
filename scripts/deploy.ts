import { GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS } from '@big-whale-labs/constants'
import { ethers, run, upgrades } from 'hardhat'
import { utils } from 'ethers'
import { version } from '../package.json'
import prompt from 'prompt'

const regexes = {
  ethereumAddress: /^0x[a-fA-F0-9]{40}$/,
}

async function main() {
  const [deployer] = await ethers.getSigners()

  // Deploy the contract
  console.log('Deploying contracts with the account:', deployer.address)
  console.log(
    'Account balance:',
    utils.formatEther(await deployer.getBalance())
  )

  const { forwarder, vcAllowMap, founderAllowMap } = await prompt.get({
    properties: {
      forwarder: {
        required: true,
        pattern: regexes.ethereumAddress,
        default: GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS,
      },
      vcAllowMap: {
        required: true,
        pattern: regexes.ethereumAddress,
        default: '0xe8c7754340b9f0efe49dfe0f9a47f8f137f70477',
      },
      founderAllowMap: {
        required: true,
        pattern: regexes.ethereumAddress,
        default: '0x91002bd44b9620866693fd8e03438e69e01563ee',
      },
    },
  })

  const provider = ethers.provider
  const { chainId } = await provider.getNetwork()
  const chains = {
    1: 'mainnet',
    3: 'ropsten',
    4: 'rinkeby',
    5: 'goerli',
    137: 'polygon',
    80001: 'mumbai',
  } as { [chainId: number]: string }
  const chainName = chains[chainId]

  const constructorArguments = [
    forwarder,
    version,
    vcAllowMap,
    founderAllowMap,
  ] as [string, string, string, string]

  const contractName = 'OBSSStorage'
  console.log(`Deploying ${contractName}...`)
  const factory = await ethers.getContractFactory(contractName)
  // const contract = await factory.deploy(...constructorArguments)
  const contract = await upgrades.deployProxy(factory, constructorArguments, {
    initializer: 'initialize',
  })

  console.log(
    'Deploy tx gas price:',
    utils.formatEther(contract.deployTransaction.gasPrice || 0)
  )
  console.log(
    'Deploy tx gas limit:',
    utils.formatEther(contract.deployTransaction.gasLimit)
  )
  await contract.deployed()

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(
    contract.address
  )
  const adminAddress = await upgrades.erc1967.getAdminAddress(contract.address)

  console.log('OBSSStorage Proxy address:', contract.address)
  console.log('Implementation address:', implementationAddress)
  console.log('Admin address:', adminAddress)

  console.log('Wait for 1 minute to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 15 * 1000))

  // Try to verify the contract on Etherscan
  console.log('Verifying contract on Etherscan')
  try {
    await run('verify:verify', {
      address: implementationAddress,
    })
  } catch (err) {
    console.log(
      'Error verifiying contract on Etherscan:',
      err instanceof Error ? err.message : err
    )
  }

  // Print out the information
  console.log(`${contractName} deployed and verified on Etherscan!`)
  console.log('Contract address:', contract.address)
  console.log(
    'Etherscan URL:',
    `https://${
      chainName !== 'polygon' ? `${chainName}.` : ''
    }polygonscan.com/address/${contract.address}`
  )
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
