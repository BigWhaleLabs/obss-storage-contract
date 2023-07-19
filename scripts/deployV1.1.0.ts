import { Feeds, OBSSStorage, Profiles } from 'typechain'
import { GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS } from '@big-whale-labs/constants'
import { chains, ethAddressRegex } from './helpers/data'
import { ethers, upgrades } from 'hardhat'
import { utils } from 'ethers'
import { version } from '../package.json'
import deployContact from './helpers/deployContract'
import prompt from 'prompt'

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

  const { isProduction } = await prompt.get({
    properties: {
      isProduction: { required: true, type: 'boolean', default: false },
    },
  })

  const {
    forwarder,
    ketlTeamTokenId,
    ketlAttestationAddress,
    obssProxyAddress,
    profilesProxyAddress,
    feedsProxyAddress,
  } = await prompt.get({
    properties: {
      forwarder: {
        required: true,
        pattern: ethAddressRegex,
        default: GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS,
      },
      ketlTeamTokenId: {
        required: true,
        type: 'number',
        default: '0',
      },
      ketlAttestationAddress: {
        required: true,
        message: 'KetlAttestationContract address',
        pattern: ethAddressRegex,
        default: isProduction ? '0x00' : '0x00',
      },
      obssProxyAddress: {
        required: true,
        message: 'OBSS Proxy address',
        pattern: ethAddressRegex,
        default: isProduction
          ? '0x1cf77299EbCF74C5367cf621Bd2cBd49e3dFD368'
          : '0xDEEbFc3aab311EA6da04fE0541074722313A4DC4',
      },
      profilesProxyAddress: {
        required: true,
        message: 'Profiles proxy address',
        pattern: ethAddressRegex,
        default: isProduction
          ? '0x95fcaf414e2ad4ca949eb725e684fd196af1fba5'
          : '0x39d8EA89705B02bc020B9E1dF369C4d746761e44',
      },
      feedsProxyAddress: {
        required: true,
        message: 'Feeds proxy address',
        type: 'string',
        pattern: ethAddressRegex,
        default: isProduction
          ? '0x9A35E42cCF1aC1772c75E2027b9D9fE56250a0a3'
          : '0x6deC0F6832772fC7F511E2ccFe1c5d046a174d5F',
      },
    },
  })

  // Deploy new Upgradeable KetlCred contract
  // (not upgrading previous one because we want to reset data)
  const ketlCredConstructorArguments = [
    'Ketl',
    'KETL',
    ketlAttestationAddress as string,
    ketlTeamTokenId as string,
    deployer.address,
    version,
  ]
  const newKetlCredContract = await deployContact({
    constructorArguments: ketlCredConstructorArguments,
    contractName: 'KetlCred',
    chainName,
    initializer: 'initializeKetlCred',
  })

  const ketlGuardedConstructorArguments = [
    ketlAttestationAddress,
    ketlTeamTokenId,
    deployer.address,
  ] as [string, string, string]

  console.log('Upgrading Feeds to v1.1.0')
  const feedsFactory = await ethers.getContractFactory('Feeds')
  const feedsContract = (await upgrades.upgradeProxy(
    feedsProxyAddress as string,
    feedsFactory
  )) as Feeds
  console.log('Feeds upgraded')
  console.log(
    await upgrades.erc1967.getImplementationAddress(feedsContract.address),
    ' getImplementationAddress'
  )
  console.log(
    await upgrades.erc1967.getAdminAddress(feedsContract.address),
    ' getAdminAddress'
  )
  await feedsContract.initialize(...ketlGuardedConstructorArguments)

  console.log('Upgrading Profiles to v1.1.0')
  const profilesFactory = await ethers.getContractFactory('Profiles')
  const profilesContract = (await upgrades.upgradeProxy(
    profilesProxyAddress as string,
    profilesFactory
  )) as Profiles
  console.log('Profiles upgraded')
  console.log(
    await upgrades.erc1967.getImplementationAddress(profilesContract.address),
    ' getImplementationAddress'
  )
  console.log(
    await upgrades.erc1967.getAdminAddress(profilesContract.address),
    ' getAdminAddress'
  )
  await profilesContract.initialize(...ketlGuardedConstructorArguments)

  console.log('Upgrading OBSSStorage to v1.1.0')
  const obssConstructorArguments = [
    forwarder,
    version,
    newKetlCredContract.address,
    profilesProxyAddress,
    feedsProxyAddress,
  ] as [string, string, string, string, string]
  const obssStorageFactory = await ethers.getContractFactory('OBSSStorage')
  const obssStorage = (await upgrades.upgradeProxy(
    obssProxyAddress as string,
    obssStorageFactory
  )) as OBSSStorage
  console.log('OBSSStorage upgraded')
  console.log(
    await upgrades.erc1967.getImplementationAddress(obssStorage.address),
    ' getImplementationAddress'
  )
  console.log(
    await upgrades.erc1967.getAdminAddress(obssStorage.address),
    ' getAdminAddress'
  )
  await obssStorage.initialize(...obssConstructorArguments)

  await newKetlCredContract.setAllowedCaller(obssStorage.address)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
