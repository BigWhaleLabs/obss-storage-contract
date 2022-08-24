import { ethers } from 'hardhat'
import { expect } from 'chai'

describe('OBSSStorage contract tests', () => {
  before(async function () {
    this.accounts = await ethers.getSigners()
    this.owner = this.accounts[0]
    this.user = this.accounts[1]
    this.factory = await ethers.getContractFactory('OBSSStorage')
  })

  describe('Constructor', function () {
    it('should deploy the contract with the correct fields', async function () {
      const version = 'v0.0.1'
      const contract = await this.factory.deploy(version)
      expect(await contract.version()).to.equal(version)
    })
  })
})
