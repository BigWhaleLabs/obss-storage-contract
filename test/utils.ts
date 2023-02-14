import { BigNumber } from 'ethers'
import { IncrementalMerkleTree } from '@zk-kit/incremental-merkle-tree'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { buildPoseidon } from 'circomlibjs'
import { randomBytes } from 'ethers/lib/utils'
import { waffle } from 'hardhat'

export async function getFakeAllowMapContract(signer: SignerWithAddress) {
  return await waffle.deployMockContract(signer, [
    {
      inputs: [
        {
          internalType: 'address',
          name: '_address',
          type: 'address',
        },
      ],
      name: 'isAddressAllowed',
      outputs: [
        {
          internalType: 'bool',
          name: '',
          type: 'bool',
        },
      ],
      stateMutability: 'view',
      type: 'function',
    },
  ])
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
