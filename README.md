# OBSS storage contract

The main storage contract. Heavily influenced by the [Big Whale Labs repos](https://github.com/BigWhaleLabs).

# Deployments

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| Proxy                       | `0x333c1990fCa4d333DEe0458fd56e1F35463c32a9` |
| Implementation(OBSSStorage) | `0x60DE8a503083F46f10Ea6d2AEd8864a97263244E` |
| Proxy Admin                 | `0x50B76E93c14F7C2DBc50608d458Bb5B5fBf3eb8E` |

## Usage

1. Clone the repository with `git clone git@github.com:backmeupplz/obss-storage-contract.git`
2. Install the dependencies with `yarn`
3. Add environment variables to your `.env` file
4. Run the scripts below

## Environment variables

| Name                         | Description                                               |
| ---------------------------- | --------------------------------------------------------- |
| `ETHERSCAN_API_KEY`          | Etherscan API key                                         |
| `ETH_RPC`                    | Ethereum RPC URL                                          |
| `CONTRACT_OWNER_PRIVATE_KEY` | Private key of the contract owner to deploy the contracts |
| `COINMARKETCAP_API_KEY`      | Coinmarketcap API key                                     |

Also check out the `.env.sample` file for more information.

## Available scripts

- `yarn build` — compiles the contract ts interface to the `typechain` directory
- `yarn test` — runs the test suite
- `yarn deploy` — deploys the contract to the network
- `yarn eth-lint` — runs the linter for the solidity contract
- `yarn lint` — runs all the linters
- `yarn prettify` — prettifies the code in th project
- `yarn release` — relases the `typechain` directory to NPM
