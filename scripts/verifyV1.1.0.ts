import { run } from 'hardhat'

async function main() {
  const DEV_OBSS_IMPLEMENTATION_ADDRESS =
    '0x52134489717Da3b27D702a7B46e36F74E2D849e5'
  const DEV_PROFILES_IMPLEMENTATION_ADDRESS =
    '0xB332225818f0D60F58A72F5F8a638C2261adca5c'
  const DEV_FEEDS_IMPLEMENTATION_ADDRESS =
    '0x47ccB9613e0e555754F24FbA380A219e9501e432'

  await run('verify:verify', { address: DEV_OBSS_IMPLEMENTATION_ADDRESS })
  await run('verify:verify', { address: DEV_PROFILES_IMPLEMENTATION_ADDRESS })
  await run('verify:verify', { address: DEV_FEEDS_IMPLEMENTATION_ADDRESS })
}

main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
