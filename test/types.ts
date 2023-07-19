import { MockContract } from 'ethereum-waffle'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import type {
  Feeds,
  Feeds__factory,
  Kred,
  Kred__factory,
  OBSSStorage,
  OBSSStorage__factory,
  Profiles,
  Profiles__factory,
} from '../typechain'

declare module 'mocha' {
  export interface Context {
    // Factories for contracts
    profilesFactory: Profiles__factory
    feedsFactory: Feeds__factory
    kredFactory: Kred__factory
    obssStorageFactory: OBSSStorage__factory
    // Contract instances
    profiles: Profiles
    feeds: Feeds
    kred: Kred
    obssStorage: OBSSStorage
    // Mock contracts
    fakeKetlAttestationContract: MockContract
    // Signers
    accounts: SignerWithAddress[]
    owner: SignerWithAddress
    user: SignerWithAddress
  }
}
