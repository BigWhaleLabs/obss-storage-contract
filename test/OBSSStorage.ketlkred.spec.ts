import { Feeds, KetlCred, OBSSStorage, Profiles } from '../typechain'
import { MOCK_CID, zeroAddress } from './utils'
import { ethers, upgrades } from 'hardhat'
import { expect } from 'chai'
import { getFakeKetlAttestationContract } from './utils/fakes'
import { version } from '../package.json'

describe('OBSSStorage: KetlCred', () => {
  before(async function () {
    this.accounts = await ethers.getSigners()
    this.owner = this.accounts[0]
    this.user = this.accounts[1]

    this.fakeKetlAttestationContract = await getFakeKetlAttestationContract(
      this.owner
    )
    await this.fakeKetlAttestationContract.mock.balanceOf.returns(1)
    await this.fakeKetlAttestationContract.mock.currentTokenId.returns(1)

    this.profilesFactory = await ethers.getContractFactory('Profiles')
    this.ketlCredFactory = await ethers.getContractFactory('KetlCred')
    this.feedsFactory = await ethers.getContractFactory('Feeds')
    this.obssStorageFactory = await ethers.getContractFactory('OBSSStorage')
  })

  describe('grantKetlCred: feedPosts', () => {
    beforeEach(async function () {
      this.profiles = (await upgrades.deployProxy(this.profilesFactory, [
        this.fakeKetlAttestationContract.address,
        0,
        this.owner.address,
      ])) as Profiles
      this.ketlCred = (await upgrades.deployProxy(
        this.ketlCredFactory,
        ['Ketl', 'KETL', 0, this.owner.address],
        {
          initializer: 'initializeKetlCred',
        }
      )) as KetlCred
      this.feeds = (await upgrades.deployProxy(this.feedsFactory, [
        this.fakeKetlAttestationContract.address,
        0,
        this.owner.address,
      ])) as Feeds
      this.obssStorage = (await upgrades.deployProxy(
        this.obssStorageFactory,
        [
          zeroAddress,
          version,
          this.ketlCred.address,
          this.profiles.address,
          this.feeds.address,
        ],
        {
          initializer: 'initialize',
        }
      )) as OBSSStorage

      await this.ketlCred.setAllowedCaller(this.obssStorage.address)
      await this.profiles.setAllowedCaller(this.obssStorage.address)
      await this.feeds.setAllowedCaller(this.obssStorage.address)

      await this.feeds.addFeed(MOCK_CID)
      await this.obssStorage.addFeedPost({
        feedId: 0,
        postMetadata: MOCK_CID,
      })
    })

    it('should grant KetlCred when feedPost is upvoted by different user', async function () {
      await this.obssStorage.connect(this.user).addFeedReaction({
        feedId: 0,
        postId: 0,
        commentId: 0,
        reactionType: 1,
      })
      expect(await this.ketlCred.balanceOf(this.owner.address)).to.equal(1)
    })
    it('should not grant KetlCred when feedPost is downvoted by user', async function () {
      await this.obssStorage.connect(this.user).addFeedReaction({
        feedId: 0,
        postId: 0,
        commentId: 0,
        reactionType: 2,
      })
      expect(await this.ketlCred.balanceOf(this.owner.address)).to.equal(0)
    })
    it('should not grant KetlCred when feedPost is upvoted by author', async function () {
      await this.obssStorage.connect(this.owner).addFeedReaction({
        feedId: 0,
        postId: 0,
        commentId: 0,
        reactionType: 1,
      })
      expect(await this.ketlCred.balanceOf(this.owner.address)).to.equal(0)
    })
    it('should not burn KetlCred when upvote is replaced with downvote', async function () {
      await this.obssStorage.connect(this.user).addFeedReaction({
        feedId: 0,
        postId: 0,
        commentId: 0,
        reactionType: 1,
      })
      const reactionBefore = await this.feeds.usersToReactions(
        0,
        0,
        0,
        this.user.address
      )
      expect(reactionBefore.reactionType).to.equal(1)
      await this.obssStorage.connect(this.user).addFeedReaction({
        feedId: 0,
        postId: 0,
        commentId: 0,
        reactionType: 2,
      })
      const reactionAfter = await this.feeds.usersToReactions(
        0,
        0,
        0,
        this.user.address
      )
      expect(reactionAfter.reactionType).to.equal(2)
      expect(await this.ketlCred.balanceOf(this.owner.address)).to.equal(1)
    })
    it('should not burn KetlCred when upvote is removed', async function () {
      await this.obssStorage.connect(this.user).addFeedReaction({
        feedId: 0,
        postId: 0,
        commentId: 0,
        reactionType: 1,
      })
      const reactionBefore = await this.feeds.usersToReactions(
        0,
        0,
        0,
        this.user.address
      )
      expect(reactionBefore.reactionType).to.equal(1)
      await this.obssStorage.connect(this.user).removeFeedReaction({
        feedId: 0,
        postId: 0,
        commentId: 0,
        reactionId: reactionBefore.reactionId,
      })
      const reactionAfter = await this.feeds.usersToReactions(
        0,
        0,
        0,
        this.user.address
      )
      expect(reactionAfter.sender).to.equal(zeroAddress)
      expect(await this.ketlCred.balanceOf(this.owner.address)).to.equal(1)
    })
  })
})
