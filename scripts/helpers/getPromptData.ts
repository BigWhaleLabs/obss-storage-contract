import { GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS } from '@big-whale-labs/constants'
import { ethAddressRegex } from './data'
import prompt from 'prompt'

export default function () {
  return prompt.get({
    properties: {
      forwarder: {
        required: true,
        pattern: ethAddressRegex,
        default: GSN_MUMBAI_FORWARDER_CONTRACT_ADDRESS,
      },
      ketlAttestation: {
        required: true,
        pattern: ethAddressRegex,
        default: '0xe2eAbeB4dA625449BE1460c54508A6202C314008',
      },
      ketlTeamTokenId: {
        required: true,
        type: 'number',
        default: '0',
      },
      shouldAddObssToPaymasterTargets: {
        type: 'boolean',
        required: true,
        default: true,
      },
      shouldAddBasicFeeds: {
        type: 'boolean',
        required: true,
        default: true,
      },
    },
  })
}
