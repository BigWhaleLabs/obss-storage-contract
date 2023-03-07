import { Contract } from 'ethers'
import { MockContract } from 'ethereum-waffle'
import type { OBSSStorage, OBSSStorage__factory } from '../typechain'
import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

declare module 'mocha' {
  export interface Context {
    // Facoriries for contracts
    factory: OBSSStorage__factory
    contract: OBSSStorage | Contract
    // Mock contracts
    fakeAllowMapContract: MockContract
    // Signers
    accounts: SignerWithAddress[]
    owner: SignerWithAddress
    user: SignerWithAddress
  }
}
