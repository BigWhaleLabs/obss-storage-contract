import { Feeds, Karma, OBSSStorage, Profiles } from '../../../typechain'
import { MOCK_CID, zeroAddress } from '../../utils'
import { ethers, upgrades } from 'hardhat'
import { expect } from 'chai'
import { getFakeKetlAttestationContract } from '../../utils/fakes'
import { version } from '../../../package.json'

describe.only('Feeds: Upgrading to v1.1.0', () => {
  it('should work', async function () {
    const accounts = await ethers.getSigners()
    const owner = accounts[0]

    const fakeKetlAttestationContract = await getFakeKetlAttestationContract(
      owner
    )
    await fakeKetlAttestationContract.mock.balanceOf.returns(1)
    await fakeKetlAttestationContract.mock.currentTokenId.returns(1)

    const profilesFactory = await ethers.getContractFactory(
      'contracts/archive/v1.0.0/Profiles.sol:Profiles'
    )
    const karmaFactory = await ethers.getContractFactory(
      'contracts/archive/v1.0.0/Karma.sol:Karma'
    )
    const feedsFactory = await ethers.getContractFactory(
      'contracts/archive/v1.0.0/Feeds.sol:Feeds'
    )
    const obssStorageFactory = await ethers.getContractFactory(
      'contracts/archive/v1.0.0/OBSSStorage.sol:OBSSStorage'
    )

    const profiles = (await upgrades.deployProxy(profilesFactory, [
      fakeKetlAttestationContract.address,
      0,
      owner.address,
    ])) as Profiles

    const karma = (await upgrades.deployProxy(
      karmaFactory,
      ['Ketl', 'KETL', 0, owner.address],
      {
        initializer: 'initializeKarma',
      }
    )) as Karma
    const feeds = (await upgrades.deployProxy(feedsFactory, [
      fakeKetlAttestationContract.address,
      0,
      owner.address,
    ])) as Feeds
    const obssStorage = (await upgrades.deployProxy(
      obssStorageFactory,
      [zeroAddress, version, karma.address, profiles.address, feeds.address],
      {
        initializer: 'initialize',
      }
    )) as OBSSStorage

    await karma.setAllowedCaller(obssStorage.address)
    await profiles.setAllowedCaller(obssStorage.address)
    await feeds.setAllowedCaller(obssStorage.address)

    await feeds.addFeed(MOCK_CID)
    await obssStorage.addFeedPost({
      feedId: 0,
      postMetadata: MOCK_CID,
    })

    const post = await feeds.posts(0, 0)
    expect(post.author).to.equal(owner.address)
    expect(post.metadata.digest).to.equal(MOCK_CID.digest)

    const newFeedsFactory = await ethers.getContractFactory(
      'contracts/Feeds.sol:Feeds'
    )
    const newFeeds = (await upgrades.upgradeProxy(
      feeds.address,
      newFeedsFactory
    )) as Feeds

    const newPost = await newFeeds.posts(0, 0)
    expect(newPost.author).to.equal(owner.address)
    expect(newPost.metadata.digest).to.equal(MOCK_CID.digest)
  })
})
