import type { OBSSStorage__factory } from '../typechain'
import type { SignerWithAddress } from '@nomiclabs/hardhat-ethers/dist/src/signer-with-address'

declare module 'mocha' {
  export interface Context {
    // Facoriries for contracts
    factory: OBSSStorage__factory
    // Signers
    accounts: SignerWithAddress[]
    owner: SignerWithAddress
    user: SignerWithAddress
  }
}
