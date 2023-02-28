import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'
import { expect } from 'chai'
import { getFakeAllowMapContract } from './utils'

const zeroAddress = '0x0000000000000000000000000000000000000000'
const MOCK_CID = {
  digest: '0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8',
  hashFunction: BigNumber.from(0),
  size: BigNumber.from(0),
}

describe('OBSSStorage contract tests', () => {
  before(async function () {
    this.accounts = await ethers.getSigners()
    this.owner = this.accounts[0]
    this.user = this.accounts[1]
    this.factory = await ethers.getContractFactory('OBSSStorage')
    this.fakeAllowMapContract = await getFakeAllowMapContract(this.owner)
  })

  describe('Constructor', function () {
    it('should deploy the contract with the correct fields', async function () {
      const version = 'v0.0.1'
      const contract = await this.factory.deploy(
        zeroAddress,
        version,
        zeroAddress,
        zeroAddress
      )
      expect(await contract.version()).to.equal(version)
    })
  })
  describe('OBSSStorage', function () {
    beforeEach(async function () {
      const version = 'v0.0.1'
      this.contract = await this.factory.deploy(
        zeroAddress,
        version,
        this.fakeAllowMapContract.address,
        this.fakeAllowMapContract.address
      )
      await this.fakeAllowMapContract.mock.isAddressAllowed.returns(true)
    })

    it('should add feed', async function () {
      expect(await this.contract.addFeed(MOCK_CID))
    })
    it('should add feed post', async function () {
      expect(await this.contract.addFeedPost(0, MOCK_CID))
    })
    it('should add profile', async function () {
      expect(await this.contract.addProfile(MOCK_CID))
    })
    it('should add profile post', async function () {
      expect(await this.contract.addProfilePost(MOCK_CID))
    })
    it('should change changeSubscriptions', async function () {
      expect(await this.contract.changeSubscriptions(MOCK_CID))
    })
    it('should add reaction', async function () {
      // Add post
      await this.contract.addFeedPost(0, MOCK_CID)
      expect(await this.contract.addReaction(0, 1))
    })
    it('should remove reaction', async function () {
      // Add post
      await this.contract.addFeedPost(0, MOCK_CID)
      // Add reaction
      await this.contract.addReaction(0, 1)
      expect(await this.contract.removeReaction(0, 1))
    })
  })
})
