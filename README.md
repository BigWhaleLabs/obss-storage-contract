# OBSS storage contract

The main storage contract. Heavily influenced by the [Big Whale Labs repos](https://github.com/BigWhaleLabs).

# Deployments

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| Proxy                       | `0xff0bd519DED90acd89B5d27Bb6Db722C0b696016` |
| Implementation(OBSSStorage) | `0xe56EcbBB9DcCFf16EAC2057Bc5A6472a696c1008` |
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
