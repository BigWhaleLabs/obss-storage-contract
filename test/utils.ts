import { BigNumber } from 'ethers'
import { IncrementalMerkleTree } from '@zk-kit/incremental-merkle-tree'
import { buildPoseidon } from 'circomlibjs'
import { randomBytes } from 'ethers/lib/utils'
import crypto from 'crypto'

export const zeroAddress = '0x0000000000000000000000000000000000000000'
export const MOCK_CID = {
  digest: '0xadb5e5a92d2bf5b6cf8744624f799e8e0e50ce0f220cb9f36ac8a1d30a17254c',
  hashFunction: BigNumber.from(0),
  size: BigNumber.from(0),
}

function generateRandomBytes32(): string {
  return `0x${crypto.randomBytes(32).toString('hex')}`
}

export async function getFakeCommitmentProof() {
  return {
    a: [1, 2],
    b: [
      [1, 2],
      [3, 4],
    ],
    c: [1, 2],
    input: await allowMapInput(),
  }
}

async function allowMapInput() {
  const randomUint256 = () => BigNumber.from(randomBytes(32)).toBigInt()
  const thousandRandomUint256 = Array.from({ length: 1000 }, randomUint256)
  const leaf = thousandRandomUint256[0]
  return {
    leaf: leaf.toString(),
    ...(await getMerkleTreeInputs(leaf, thousandRandomUint256)),
  }
}

export async function getMerkleTreeInputs(
  commitment: bigint | string,
  commitments: (bigint | string)[]
) {
  const proof = await getMerkleTreeProof(commitment, commitments)

  return {
    pathIndices: proof.pathIndices,
    pathElements: proof.siblings.map(([s]) => BigNumber.from(s).toHexString()),
  }
}

export default async function getMerkleTreeProof(
  commitment: bigint | string,
  commitments: (bigint | string)[]
) {
  const poseidon = await buildPoseidon()
  const F = poseidon.F
  const tree = new IncrementalMerkleTree(
    (values) => BigInt(F.toString(poseidon(values))),
    15,
    BigInt(0),
    2
  )
  commitments.forEach((c) => tree.insert(c))
  return tree.createProof(tree.indexOf(commitment))
}

export function getFeedPostsBatch(length = 10) {
  const posts: {
    feedId: number
    postMetadata: {
      digest: string
      hashFunction: BigNumber
      size: BigNumber
    }
  }[] = []

  for (let i = 0; i < length; i++) {
    posts.push({
      feedId: 0,
      postMetadata: {
        digest: generateRandomBytes32(),
        hashFunction: BigNumber.from(0),
        size: BigNumber.from(0),
      },
    })
    posts[i].postMetadata.digest = generateRandomBytes32()
  }

  return posts
}
