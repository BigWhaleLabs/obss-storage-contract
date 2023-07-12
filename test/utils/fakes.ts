import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { allowMapInput } from '.'
import { deployMockContract } from 'ethereum-waffle'

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

export async function getFakeKetlAttestationContract(
  signer: SignerWithAddress
) {
  return await deployMockContract(signer, [
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
}
