import { CIDStruct } from '../../typechain/contracts/Feeds'

const hashAndSize = { hashFunction: 18, size: 32 }

export default [
  {
    // t/devFeed
    digest:
      '0xa512e411f65d0efa40d42a7332ddcb24725e0714a9d2d22f997dfd176b5a7f1e',
    ...hashAndSize,
  },
  {
    // t/startups
    digest:
      '0x8072f46c4c61b73c28af62340b47cb40ccba9d1b115fd43d5ed21a31f6c9009b',
    ...hashAndSize,
  },
  {
    // t/ketlTeam
    digest:
      '0x0b071ef9c2bb401453036d9c96debd2c9478ec185f2a903edaf5afff2ae791db',
    ...hashAndSize,
  },
] as CIDStruct[]
