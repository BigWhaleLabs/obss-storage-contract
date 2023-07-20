import { ethers, upgrades } from 'hardhat'

async function main() {
  const DEV_OBSS_PROXY_ADDRESS = '0xDEEbFc3aab311EA6da04fE0541074722313A4DC4'
  const DEV_PROFILES_PROXY_ADDRESS =
    '0x39d8EA89705B02bc020B9E1dF369C4d746761e44'
  const DEV_FEEDS_PROXY_ADDRESS = '0x6deC0F6832772fC7F511E2ccFe1c5d046a174d5F'
  const PROD_OBSS_PROXY_ADDRESS = '0x1cf77299EbCF74C5367cf621Bd2cBd49e3dFD368'
  const PROD_PROFILES_PROXY_ADDRESS =
    '0x95fcaf414e2ad4ca949eb725e684fd196af1fba5'
  const PROD_FEEDS_PROXY_ADDRESS = '0x9A35E42cCF1aC1772c75E2027b9D9fE56250a0a3'

  const feedsFactory = await ethers.getContractFactory('Feeds')
  await upgrades.forceImport(DEV_FEEDS_PROXY_ADDRESS, feedsFactory)
  // await upgrades.forceImport(PROD_FEEDS_PROXY_ADDRESS, feedsFactory)

  const profilesFactory = await ethers.getContractFactory('Profiles')
  await upgrades.forceImport(DEV_PROFILES_PROXY_ADDRESS, profilesFactory)
  // await upgrades.forceImport(PROD_PROFILES_PROXY_ADDRESS, profilesFactory)

  const obssStorageFactory = await ethers.getContractFactory('OBSSStorage')
  await upgrades.forceImport(DEV_OBSS_PROXY_ADDRESS, obssStorageFactory)
  // await upgrades.forceImport(PROD_OBSS_PROXY_ADDRESS, obssStorageFactory)
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
