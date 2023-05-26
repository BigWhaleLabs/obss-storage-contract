# OBSS storage contract

The main storage contract made specially for [Big Whale Labs projects](https://github.com/BigWhaleLabs).

# Deployments

| Contract                    | Address                                      |
| --------------------------- | -------------------------------------------- |
| Proxy                       | `0x320E80744Af5C485B9fCFE2102E6E5d4B21D2743` |
| Implementation(OBSSStorage) | `0xfC79654612F35A2E9660e665aF6214052fDe241A` |
| Proxy Admin                 | `0x619Ec5c3fc767dFbC6e359Ea520b1ab512d87916` |

## Usage

1. Clone the repository with `git clone https://github.com/BigWhaleLabs/obss-storage-contract.git`
2. Install the dependencies with `yarn`
3. Add environment variables to your `.env` file
4. Run the scripts below

## Environment variables

| Name                         | Description                                                                                   |
| ---------------------------- | --------------------------------------------------------------------------------------------- |
| `ETHERSCAN_API_KEY`          | Etherscan API key                                                                             |
| `ETH_RPC`                    | Ethereum RPC URL                                                                              |
| `CONTRACT_OWNER_PRIVATE_KEY` | Private key of the contract owner to deploy the contracts                                     |
| `COINMARKETCAP_API_KEY`      | Coinmarketcap API key                                                                         |
| `GSN_PAYMASTER_CONTRACT`     | Paymaster contract to add deployed OBSS into targets automatically, defaults to BWL constants |

Also check out the `.env.sample` file for more information.

## Available scripts

- `yarn build` — compiles the contract ts interface to the `typechain` directory
- `yarn test` — runs the test suite
- `yarn deploy` — deploys the contract to the network. After deploying go to blockchain scanner address in the console and verify your contract as proxy to use it
- `yarn eth-lint` — runs the linter for the solidity contract
- `yarn lint` — runs all the linters
- `yarn prettify` — prettifies the code in th project
- `yarn release` — releases the `typechain` directory to NPM
