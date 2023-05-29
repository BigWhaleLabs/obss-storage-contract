import { GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS } from '@big-whale-labs/constants'
import { ethers } from 'hardhat'
import { utils } from 'ethers'
import { version } from '../package.json'
import addBasicFeeds from './helpers/addBasicFeeds'
import addContractToPaymaster from './helpers/addContractToPaymaster'
import deployContact from './deployContract'
import prompt from 'prompt'

const ethereumRegex = /^0x[a-fA-F0-9]{40}$/

async function main() {
  const [deployer] = await ethers.getSigners()

  // Deploy the contract
  console.log('Deploying contracts with the account:', deployer.address)
  console.log(
    'Account balance:',
    utils.formatEther(await deployer.getBalance())
  )

  const {
    forwarder,
    ketlAttestation,
    ketlTeamTokenId,
    shouldAddBasicFeeds,
    shouldAddObssToPaymasterTargets,
  } = await prompt.get({
    properties: {
      forwarder: {
        required: true,
        pattern: ethereumRegex,
        default: GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS,
      },
      ketlAttestation: {
        required: true,
        pattern: ethereumRegex,
        default: '0xe2eAbeB4dA625449BE1460c54508A6202C314008',
      },
      ketlTeamTokenId: {
        required: true,
        type: 'number',
        default: '0',
      },
      shouldAddObssToPaymasterTargets: {
        type: 'boolean',
        required: true,
        default: true,
      },
      shouldAddBasicFeeds: {
        type: 'boolean',
        required: true,
        default: true,
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

  const profilesConstructorArguments = [
    ketlAttestation,
    ketlTeamTokenId,
    deployer.address,
  ] as [string, string, string]
  const profilesContract = await deployContact({
    constructorArguments: profilesConstructorArguments,
    contractName: 'Profiles',
    chainName,
  })

  const karmaConstructorArguments = [
    'Kekl',
    'KEK',
    ketlTeamTokenId as string,
    deployer.address,
  ]
  const karmaContract = await deployContact({
    constructorArguments: karmaConstructorArguments,
    contractName: 'Karma',
    chainName,
    initializer: 'initializeKarma',
  })

  const feedsConstructorArguments = [
    ketlAttestation,
    ketlTeamTokenId,
    deployer.address,
  ] as [string, string, string]
  const feedsContract = await deployContact({
    constructorArguments: feedsConstructorArguments,
    contractName: 'Feeds',
    chainName,
  })
  if (shouldAddBasicFeeds) await addBasicFeeds(feedsContract.address, deployer)

  const obssConstructorArguments = [
    forwarder,
    version,
    karmaContract.address,
    profilesContract.address,
    feedsContract.address,
  ] as [string, string, string, string, string]
  const obss = await deployContact({
    constructorArguments: obssConstructorArguments,
    contractName: 'OBSSStorage',
    chainName,
  })
  if (shouldAddObssToPaymasterTargets)
    await addContractToPaymaster(obss.address, deployer)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
