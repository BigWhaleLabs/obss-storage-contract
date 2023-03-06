import { ethers, upgrades } from 'hardhat'
import prompt from 'prompt'

const regexes = {
  ethereumAddress: /^0x[a-fA-F0-9]{40}$/,
}

async function main() {
  const OBSSStorage = await ethers.getContractFactory('OBSSStorage')
  const { proxyAddress } = await prompt.get({
    properties: {
      proxyAddress: {
        required: true,
        message: 'Proxy address',
        pattern: regexes.ethereumAddress,
      },
    },
  })
  console.log('Upgrading OBSSStorage...')
  await upgrades.upgradeProxy(proxyAddress as string, OBSSStorage)
  console.log('OBSSStorage upgraded')
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
