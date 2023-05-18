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

  const { forwarder, ketlAttestation } = await prompt.get({
    properties: {
      forwarder: {
        required: true,
        pattern: regexes.ethereumAddress,
        default: GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS,
      },
      ketlAttestation: {
        required: true,
        pattern: regexes.ethereumAddress,
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

  const profilesContractName = 'Profiles'
  console.log(`Deploying ${profilesContractName}...`)
  const profilesFactory = await ethers.getContractFactory(profilesContractName)
  const profilesContract = await upgrades.deployProxy(
    profilesFactory,
    profilesConstructorArguments,
    {
      initializer: 'initialize',
    }
  )
  console.log(
    'Deploy tx gas price:',
    utils.formatEther(profilesContract.deployTransaction.gasPrice || 0)
  )
  console.log(
    'Deploy tx gas limit:',
    utils.formatEther(profilesContract.deployTransaction.gasLimit)
  )
  await profilesContract.deployed()

  const profilesImplementationAddress =
    await upgrades.erc1967.getImplementationAddress(profilesContract.address)
  const profilesAdminAddress = await upgrades.erc1967.getAdminAddress(
    profilesContract.address
  )

  console.log('Profiles Proxy address:', profilesContract.address)
  console.log('Implementation address:', profilesImplementationAddress)
  console.log('Admin address:', profilesAdminAddress)

  console.log('Wait for 1 minute to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 15 * 1000))

  // Try to verify the contract on Etherscan
  console.log('Verifying contract on Etherscan')
  try {
    await run('verify:verify', {
      address: profilesImplementationAddress,
    })
  } catch (err) {
    console.log(
      'Error verifiying contract on Etherscan:',
      err instanceof Error ? err.message : err
    )
  }

  // Print out the information
  console.log(`${profilesContractName} deployed and verified on Etherscan!`)
  console.log('Karma contract address:', profilesContract.address)

  // Karma

  const karmaConstructorArguments = ['Kekl', 'KEK', deployer.address] as [
    string,
    string,
    string
  ]

  const karmaContractName = 'Karma'
  console.log(`Deploying ${karmaContractName}...`)
  const karmaFactory = await ethers.getContractFactory(karmaContractName)
  const karmaContract = await upgrades.deployProxy(
    karmaFactory,
    karmaConstructorArguments,
    {
      initializer: 'initialize',
    }
  )
  console.log(
    'Deploy tx gas price:',
    utils.formatEther(karmaContract.deployTransaction.gasPrice || 0)
  )
  console.log(
    'Deploy tx gas limit:',
    utils.formatEther(karmaContract.deployTransaction.gasLimit)
  )
  await karmaContract.deployed()

  const karmaImplementationAddress =
    await upgrades.erc1967.getImplementationAddress(karmaContract.address)
  const karmaAdminAddress = await upgrades.erc1967.getAdminAddress(
    karmaContract.address
  )

  console.log('Karma Proxy address:', karmaContract.address)
  console.log('Implementation address:', karmaImplementationAddress)
  console.log('Admin address:', karmaAdminAddress)

  console.log('Wait for 1 minute to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 15 * 1000))

  // Try to verify the contract on Etherscan
  console.log('Verifying contract on Etherscan')
  try {
    await run('verify:verify', {
      address: karmaImplementationAddress,
    })
  } catch (err) {
    console.log(
      'Error verifiying contract on Etherscan:',
      err instanceof Error ? err.message : err
    )
  }

  // Print out the information
  console.log(`${karmaContractName} deployed and verified on Etherscan!`)
  console.log('Karma contract address:', karmaContract.address)

  // Feeds

  const feedsConstructorArguments = ['Kekl', 'KEK', deployer.address] as [
    string,
    string,
    string
  ]

  const feedsContractName = 'Feeds'
  console.log(`Deploying ${feedsContractName}...`)
  const feedsFactory = await ethers.getContractFactory(feedsContractName)
  const feedsContract = await upgrades.deployProxy(
    feedsFactory,
    feedsConstructorArguments,
    {
      initializer: 'initialize',
    }
  )
  console.log(
    'Deploy tx gas price:',
    utils.formatEther(feedsContract.deployTransaction.gasPrice || 0)
  )
  console.log(
    'Deploy tx gas limit:',
    utils.formatEther(feedsContract.deployTransaction.gasLimit)
  )
  await feedsContract.deployed()

  const feedsImplementationAddress =
    await upgrades.erc1967.getImplementationAddress(feedsContract.address)
  const feedsAdminAddress = await upgrades.erc1967.getAdminAddress(
    feedsContract.address
  )

  console.log('Feeds Proxy address:', feedsContract.address)
  console.log('Implementation address:', feedsImplementationAddress)
  console.log('Admin address:', feedsAdminAddress)

  console.log('Wait for 1 minute to make sure blockchain is updated')
  await new Promise((resolve) => setTimeout(resolve, 15 * 1000))

  // Try to verify the contract on Etherscan
  console.log('Verifying contract on Etherscan')
  try {
    await run('verify:verify', {
      address: feedsImplementationAddress,
    })
  } catch (err) {
    console.log(
      'Error verifiying contract on Etherscan:',
      err instanceof Error ? err.message : err
    )
  }

  // Print out the information
  console.log(`${karmaContractName} deployed and verified on Etherscan!`)
  console.log('Karma contract address:', karmaContract.address)

  // OBSS

  const constructorArguments = [
    forwarder,
    version,
    karmaContract.address,
    profilesContract.address,
    feedsContract.address,
  ] as [string, string, string, string, string]

  const contractName = 'OBSSStorage'
  console.log(`Deploying ${contractName}...`)
  const factory = await ethers.getContractFactory(contractName)
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
