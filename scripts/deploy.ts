import { chains } from './helpers/data'
import { ethers } from 'hardhat'
import { utils } from 'ethers'
import { version } from '../package.json'
import addBasicFeeds from './helpers/addBasicFeeds'
import addContractToPaymaster from './helpers/addContractToPaymaster'
import deployContact from './deployContract'
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

  const ketlCredConstructorArguments = [
    'Ketl',
    'KETL',
    ketlTeamTokenId as string,
    deployer.address,
  ]
  const ketlCredContract = await deployContact({
    constructorArguments: ketlCredConstructorArguments,
    contractName: 'KetlCred',
    chainName,
    initializer: 'initializeKetlCred',
  })

  const feedsContract = await deployContact({
    constructorArguments,
    contractName: 'Feeds',
    chainName,
  })

  const obssConstructorArguments = [
    forwarder,
    version,
    ketlCredContract.address,
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

  await ketlCredContract.setAllowedCaller(obss.address)
  await profilesContract.setAllowedCaller(obss.address)
  await feedsContract.setAllowedCaller(obss.address)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
