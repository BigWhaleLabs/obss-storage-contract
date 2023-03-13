import {
  MOCK_CID,
  getFakeAllowMapContract,
  getFeedPostsBatch,
  getReactionsBatch,
  zeroAddress,
} from './utils'
import { ethers, upgrades } from 'hardhat'
import { expect } from 'chai'

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
      const contract = await upgrades.deployProxy(
        this.factory,
        [
          zeroAddress,
          version,
          this.fakeAllowMapContract.address,
          this.fakeAllowMapContract.address,
        ],
        {
          initializer: 'initialize',
        }
      )
      expect(await contract.version()).to.equal(version)
    })
  })
  describe('OBSSStorage', function () {
    beforeEach(async function () {
      const version = 'v0.0.1'
      this.contract = await upgrades.deployProxy(
        this.factory,
        [
          zeroAddress,
          version,
          this.fakeAllowMapContract.address,
          this.fakeAllowMapContract.address,
        ],
        {
          initializer: 'initialize',
        }
      )
      await this.fakeAllowMapContract.mock.isAddressAllowed.returns(true)
    })

    it('should add feed', async function () {
      expect(await this.contract.addFeed(MOCK_CID))
    })
    it('should add feed post', async function () {
      expect(await this.contract.addFeedPost(0, MOCK_CID))
    })
    it('should add batch feed post', async function () {
      const posts = getFeedPostsBatch()
      expect(await this.contract.addBatchFeedPost(posts))
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
    it('should add batch reactions', async function () {
      // Add batch posts
      const posts = getFeedPostsBatch()
      await this.contract.addBatchFeedPost(posts)

      const reactions = getReactionsBatch()
      expect(await this.contract.addBatchReactions(reactions))
    })
    it('should remove reaction', async function () {
      // Add post
      await this.contract.addFeedPost(0, MOCK_CID)
      // Add reaction
      await this.contract.addReaction(0, 1)
      expect(await this.contract.removeReaction(0, 1))
    })
    it('should remove batch reactions', async function () {
      // Add batch posts
      const posts = getFeedPostsBatch()
      await this.contract.addBatchFeedPost(posts)

      for (let i = 0; i < 10; i++) {
        await this.contract.addReaction(i, 1)
      }

      const reactions = getReactionsBatch()
      expect(await this.contract.removeBatchReactions(reactions))
    })
    it('successful call `batchReactionsAndPosts`', async function () {
      // Add batch posts
      const posts = getFeedPostsBatch()
      await this.contract.addBatchFeedPost(posts)

      const reactions = getReactionsBatch()
      expect(
        await this.contract.batchReactionsAndPosts(posts, reactions, reactions)
      )
    })
  })
})
