import { ethAddressRegex } from './helpers/data'
import { ethers, upgrades } from 'hardhat'
import prompt from 'prompt'

async function main() {
  const factory = await ethers.getContractFactory('OBSSStorage')
  const { proxyAddress } = await prompt.get({
    properties: {
      proxyAddress: {
        required: true,
        message: 'Proxy address',
        pattern: ethAddressRegex,
        default: '0x333c1990fCa4d333DEe0458fd56e1F35463c32a9',
      },
    },
  })
  console.log('Upgrading OBSSStorage...')
  const contract = await upgrades.upgradeProxy(proxyAddress as string, factory)
  console.log('OBSSStorage upgraded')
  console.log(
    await upgrades.erc1967.getImplementationAddress(contract.address),
    ' getImplementationAddress'
  )
  console.log(
    await upgrades.erc1967.getAdminAddress(contract.address),
    ' getAdminAddress'
  )
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
