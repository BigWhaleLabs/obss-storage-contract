import type { OBSSStorage__factory } from '../typechain'

declare module 'mocha' {
  export interface Context {
    factory: OBSSStorage__factory
  }
}
