import { ethers, upgrades } from 'hardhat'
import { expect } from 'chai'
import { zeroAddress } from './utils'

describe('OBSSStorage contract tests', () => {
  before(async function () {
    this.obssStorageFactory = await ethers.getContractFactory('OBSSStorage')
  })

  describe('Constructor', function () {
    it('should deploy the contract with the correct fields', async function () {
      const version = 'v0.0.1'
      const contract = await upgrades.deployProxy(
        this.obssStorageFactory,
        [zeroAddress, version, zeroAddress, zeroAddress, zeroAddress],
        {
          initializer: 'initialize',
        }
      )
      expect(await contract.version()).to.equal(version)
    })
  })
})
