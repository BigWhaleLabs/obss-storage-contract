import {
  DEV_KETL_ATTESTATION_CONTRACT,
  DEV_KETL_CRED_CONTRACT_ADDRESS,
  DEV_KETL_FEEDS_CONTRACT_ADDRESS,
  PROD_KETL_ATTESTATION_CONTRACT,
  PROD_KETL_CRED_CONTRACT_ADDRESS,
  PROD_KETL_FEEDS_CONTRACT_ADDRESS,
} from '@big-whale-labs/constants'
import { ethAddressRegex } from './helpers/data'
import { ethers } from 'hardhat'
import prompt from 'prompt'

async function main() {
  const { isProduction } = await prompt.get({
    properties: {
      isProduction: { required: true, type: 'boolean', default: false },
    },
  })

  const {
    ketlAttestationAddress,
    kredProxyAddress,
    profilesProxyAddress,
    feedsProxyAddress,
  } = await prompt.get({
    properties: {
      ketlAttestationAddress: {
        required: true,
        message: 'KetlAttestationContract address',
        pattern: ethAddressRegex,
        default: isProduction
          ? PROD_KETL_ATTESTATION_CONTRACT
          : DEV_KETL_ATTESTATION_CONTRACT,
      },
      kredProxyAddress: {
        required: true,
        message: 'Kred Proxy address',
        pattern: ethAddressRegex,
        default: isProduction
          ? PROD_KETL_CRED_CONTRACT_ADDRESS
          : DEV_KETL_CRED_CONTRACT_ADDRESS,
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
          ? PROD_KETL_FEEDS_CONTRACT_ADDRESS
          : DEV_KETL_FEEDS_CONTRACT_ADDRESS,
      },
    },
  })

  const kredContract = await ethers.getContractAt(
    'Kred',
    kredProxyAddress as string
  )
  const setKredAttestationTx = await kredContract.setAttestationToken(
    ketlAttestationAddress as string
  )
  await setKredAttestationTx.wait()
  console.log('Updated attestationToken on Kred contract')

  const feedsContract = await ethers.getContractAt(
    'Feeds',
    feedsProxyAddress as string
  )
  const setFeedsAttestationTx = await feedsContract.setAttestationToken(
    ketlAttestationAddress as string
  )
  await setFeedsAttestationTx.wait()
  console.log('Updated attestationToken on Feeds contract')

  const profilesContract = await ethers.getContractAt(
    'Profiles',
    profilesProxyAddress as string
  )
  const setProfilesAttestationTx = await profilesContract.setAttestationToken(
    ketlAttestationAddress as string
  )
  await setProfilesAttestationTx.wait()
  console.log('Updated attestationToken on Profiles contract')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
