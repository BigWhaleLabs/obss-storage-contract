import { chains } from './helpers/data'
import { ethers } from 'hardhat'
import { utils } from 'ethers'
import { version } from '../package.json'
import addBasicFeeds from './helpers/addBasicFeeds'
import addContractToPaymaster from './helpers/addContractToPaymaster'
import deployContact from './helpers/deployContract'
import getPromptData from './helpers/getPromptData'

async function main() {
  const [deployer] = await ethers.getSigners()

  const provider = ethers.provider

  const { chainId } = await provider.getNetwork()
  const chainName = chains[chainId]

  // Deploy the contract
  console.log('Deploying contracts with the account:', deployer.address)
  console.log('Using network:', chainName)
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
  } = await getPromptData()

  const constructorArguments = [
    ketlAttestation,
    ketlTeamTokenId,
    deployer.address,
  ] as [string, string, string]
  const profilesContract = await deployContact({
    constructorArguments,
    contractName: 'Profiles',
    chainName,
  })

  const kredConstructorArguments = [
    'Kred',
    'KRED',
    ketlTeamTokenId as string,
    deployer.address,
  ]
  const kredContract = await deployContact({
    constructorArguments: kredConstructorArguments,
    contractName: 'Kred',
    chainName,
    initializer: 'initializeKred',
  })

  const feedsContract = await deployContact({
    constructorArguments,
    contractName: 'Feeds',
    chainName,
  })

  const obssConstructorArguments = [
    forwarder,
    version,
    kredContract.address,
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

  if (shouldAddBasicFeeds) await addBasicFeeds(feedsContract.address, deployer)

  await kredContract.setAllowedCaller(obss.address)
  await profilesContract.setAllowedCaller(obss.address)
  await feedsContract.setAllowedCaller(obss.address)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
