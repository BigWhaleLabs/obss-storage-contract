import { MOCK_CID, zeroAddress } from './utils'
import { ethers, upgrades } from 'hardhat'
import { smock } from '@defi-wonderland/smock'
import { version } from '../package.json'

import { expect } from 'chai'

import { Feeds, KetlCred, OBSSStorage, Profiles } from 'typechain'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

describe('OBSSStorage: KetlKred', () => {
  async function setupOBSS() {
    const [deployer, user] = await ethers.getSigners()

    const ketlAttestationContractMock = await smock.fake([
      {
        inputs: [
          { internalType: 'address', name: 'account', type: 'address' },
          { internalType: 'uint256', name: 'id', type: 'uint256' },
        ],
        name: 'balanceOf',
        outputs: [{ internalType: 'uint256', name: '', type: 'uint256' }],
        stateMutability: 'view',
        type: 'function',
      },
      {
        inputs: [],
        name: 'currentTokenId',
        outputs: [{ internalType: 'uint32', name: '', type: 'uint32' }],
        stateMutability: 'view',
        type: 'function',
      },
    ])
    ketlAttestationContractMock.balanceOf.returns(1)
    ketlAttestationContractMock.currentTokenId.returns(1)

    const profilesContractFactory = await ethers.getContractFactory('Profiles')
    const profilesContract = (await upgrades.deployProxy(
      profilesContractFactory,
      [ketlAttestationContractMock.address, 0, deployer.address]
    )) as Profiles
    await profilesContract.deployed()

    const ketlCredContractFactory = await ethers.getContractFactory('KetlCred')
    const ketlCredContract = (await upgrades.deployProxy(
      ketlCredContractFactory,
      ['Ketl', 'KETL', 0, deployer.address],
      {
        initializer: 'initializeKetlCred',
      }
    )) as KetlCred
    await ketlCredContract.deployed()

    const feedsContractFactory = await ethers.getContractFactory('Feeds')
    const feedsContract = (await upgrades.deployProxy(feedsContractFactory, [
      ketlAttestationContractMock.address,
      0,
      deployer.address,
    ])) as Feeds
    await feedsContract.deployed()

    const obssStorageFactory = await ethers.getContractFactory('OBSSStorage')
    const obssStorageContract = (await upgrades.deployProxy(
      obssStorageFactory,
      [
        zeroAddress,
        version,
        ketlCredContract.address,
        profilesContract.address,
        feedsContract.address,
      ],
      {
        initializer: 'initialize',
      }
    )) as OBSSStorage
    await obssStorageContract.deployed()

    await ketlCredContract.setAllowedCaller(obssStorageContract.address)
    await profilesContract.setAllowedCaller(obssStorageContract.address)
    await feedsContract.setAllowedCaller(obssStorageContract.address)

    return {
      deployer,
      user,
      profilesContract,
      ketlCredContract,
      feedsContract,
      obssStorageContract,
    }
  }

  it('should grant KetlCred to author when post is upvoted', async function () {
    const {
      user,
      deployer,
      feedsContract,
      obssStorageContract,
      ketlCredContract,
    } = await loadFixture(setupOBSS)
    await feedsContract.addFeed(MOCK_CID)
    expect(await feedsContract.lastFeedId()).to.equal(1)
    await obssStorageContract.addFeedPost({
      feedId: 0,
      postMetadata: MOCK_CID,
    })
    await obssStorageContract.connect(user).addFeedReaction({
      feedId: 0,
      postId: 0,
      commentId: 0,
      reactionType: 1,
    })
    expect(await ketlCredContract.balanceOf(deployer.address)).to.equal(1)
  })
})
