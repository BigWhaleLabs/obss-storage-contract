import { ethers } from 'hardhat'
import { expect } from 'chai'

const struct = {
  digest: '0x55af6607dd06a5d5539bafd36edaef232ab59eee401d098b9268b780953adbe7',
  hashFunction: 18,
  size: 32,
}

describe('OBSSStorage contract tests', () => {
  before(async function () {
    this.accounts = await ethers.getSigners()
    this.owner = this.accounts[0]
    this.user = this.accounts[1]
    this.version = 'v0.0.4'
    this.obssStorageFactory = await ethers.getContractFactory('OBSSStorage')
  })
  beforeEach(async function () {
    this.obssStorage = await this.obssStorageFactory.deploy(this.version)
  })
  describe('Contract', function () {
    it('should deploy the contract with the correct fields', async function () {
      const version = 'v0.0.4'
      expect(await this.obssStorage.version()).to.equal(version)
    })
  })
  describe('Community', function () {
    it('should return an empty list of communities', async function () {
      expect(await this.obssStorage.getCommunities()).to.have.length(0)
    })
    it('should add a community', async function () {
      const expectCommunity = [
        '0x55af6607dd06a5d5539bafd36edaef232ab59eee401d098b9268b780953adbe7',
        18,
        32,
      ]
      await this.obssStorage.addCommunity(struct)
      expect(await this.obssStorage.communities(0)).to.equal(expectCommunity)
    })
  })
})
