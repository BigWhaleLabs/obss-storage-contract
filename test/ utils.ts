import { OBSSStorage } from 'typechain/contracts/OBSSStorage'

export default function serializeCommunities(
  communities: OBSSStorage.CIDStructOutput[]
) {
  return communities.map((community) => ({
    digest: community.digest,
    hashFunction: community.hashFunction,
    size: community.size,
  }))
}
