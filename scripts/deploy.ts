import { GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS } from '@big-whale-labs/constants'
import { ethers, run, upgrades } from 'hardhat'
import { utils } from 'ethers'
import { version } from '../package.json'
import prompt from 'prompt'

const ethereumRegex = /^0x[a-fA-F0-9]{40}$/

function parseError(error: unknown) {
  error instanceof Error ? error.message : error
}

async function deployContact({
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
  console.log('Implementation address: ', contractImplementationAddress)
  console.log('Admin address: ', contractAdminAddress)

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
    'Scanner URL:',
    `https://${
      chainName === 'polygon' ? '' : `${chainName}.`
    }polygonscan.com/address/${contract.address}`
  )
  console.log('---------------')

  return contract
}

async function main() {
  const [deployer] = await ethers.getSigners()

  // Deploy the contract
  console.log('Deploying contracts with the account:', deployer.address)
  console.log(
    'Account balance:',
    utils.formatEther(await deployer.getBalance())
  )

  const { forwarder, ketlAttestation } = await prompt.get({
    properties: {
      forwarder: {
        required: true,
        pattern: ethereumRegex,
        default: GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS,
      },
      ketlAttestation: {
        required: true,
        pattern: ethereumRegex,
        default: '0xc98cD68E59D8C25Fc2FaF1A09Ea8010Ad4D6D52f',
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

  const profilesConstructorArguments = [ketlAttestation, deployer.address] as [
    string,
    string
  ]
  const profilesContract = await deployContact({
    constructorArguments: profilesConstructorArguments,
    contractName: 'Profiles',
    chainName,
  })

  const karmaConstructorArguments = ['Kekl', 'KEK', deployer.address]
  const karmaContract = await deployContact({
    constructorArguments: karmaConstructorArguments,
    contractName: 'Karma',
    chainName,
    initializer: 'initializeKarma',
  })

  const feedsConstructorArguments = [ketlAttestation, deployer.address] as [
    string,
    string
  ]
  const feedsContract = await deployContact({
    constructorArguments: feedsConstructorArguments,
    contractName: 'Feeds',
    chainName,
  })

  // OBSSStorage
  const obssConstructorArguments = [
    forwarder,
    version,
    karmaContract.address,
    profilesContract.address,
    feedsContract.address,
  ] as [string, string, string, string, string]
  await deployContact({
    constructorArguments: obssConstructorArguments,
    contractName: 'OBSSStorage',
    chainName,
  })
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
