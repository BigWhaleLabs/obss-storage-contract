import { Kred, OBSSStorage } from '../typechain'
import { chains, ethAddressRegex } from './helpers/data'
import { ethers } from 'hardhat'
import { utils } from 'ethers'
import { version } from '../package.json'
import deployContact from './helpers/deployContract'
import prompt from 'prompt'
import upgradeContract from './helpers/upgradeContract'

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
    ketlTeamTokenId,
    ketlAttestationAddress,
    obssProxyAddress,
    profilesProxyAddress,
    feedsProxyAddress,
  } = await prompt.get({
    properties: {
      ketlTeamTokenId: {
        required: true,
        type: 'number',
        default: '0',
      },
      ketlAttestationAddress: {
        required: true,
        message: 'KetlAttestationContract address',
        pattern: ethAddressRegex,
        default: isProduction
          ? '0x929Da562A21Fb8bc5f0408Bf6D63e0c82b6f0c4B'
          : '0x550060f9b15Ae39F924fAbd80958eAB2361Da2D1',
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
        pattern: ethAddressRegex,
        default: isProduction
          ? '0x9A35E42cCF1aC1772c75E2027b9D9fE56250a0a3'
          : '0x6deC0F6832772fC7F511E2ccFe1c5d046a174d5F',
      },
    },
  })

  console.log('Deploying Kred v1.1.1')
  // (not upgrading previous one because we want to reset data)
  const kredConstructorArguments = [
    'Kred',
    'KRED',
    ketlAttestationAddress as string,
    String(ketlTeamTokenId),
    deployer.address,
    version,
  ]
  const newKredContract = (await deployContact({
    constructorArguments: kredConstructorArguments,
    contractName: 'Kred',
    chainName,
    initializer: 'initializeKred',
  })) as Kred

  // console.log('Upgrading Feeds to v1.1.1')
  await upgradeContract({
    proxyAddress: feedsProxyAddress as string,
    contractName: 'Feeds',
    chainName,
  })

  // console.log('Upgrading Profiles to v1.1.1')
  await upgradeContract({
    proxyAddress: profilesProxyAddress as string,
    contractName: 'Profiles',
    chainName,
  })

  console.log('Upgrading OBSSStorage to v1.1.1')
  const obssStorage = (await upgradeContract({
    proxyAddress: obssProxyAddress as string,
    contractName: 'OBSSStorage',
    chainName,
  })) as OBSSStorage

  await newKredContract.setAllowedCaller(obssStorage.address)
  await obssStorage.setKredContract(newKredContract.address)
  await obssStorage.setVersion(version)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
