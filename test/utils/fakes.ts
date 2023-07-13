import { KetlAttestation__factory } from '@big-whale-labs/ketl-attestation-token'
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
  return await deployMockContract(signer, [...KetlAttestation__factory.abi])
}
