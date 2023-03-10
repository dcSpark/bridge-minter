# Plutus Minting & Burning Contract

# Usage

This contract is meant to create a unique minting and burning contract for every
ERC721 smart contract that is bridged to the Cardano blockchain.

The ERC721 id is used to configure the smart contract, along with a "permission NFT" policy id and token name. Using the ERC721 id as part of the configuration ensures the policy id for the NFTs are unique. The permission NFT is required to be spent in either the minting or burning transaction.

Multiple NFTs can be minted or burned in a transaction. However, to ensure that NFTs are minted, only one token for each token name can be minted in a transactions.

# Assets

The compiled Plutus script is checked in to the following location:
- `assets/bridge.plutus`
- `assets/bridge-policy-id.txt`

# Compiling

Compliation has been validated with GHC 8.10.7.

To compile call the compile script:

```bash
./scripts/compile
```

# Example Transaction

Example transactions are provided in the folder `scripts/happy-path`.

### ⚠️ Warning
Running the example transactions requires `cardano-cli-balance-fixer` which can installed from this repo: https://github.com/Canonical-LLC/cardano-cli-balance-fixer

First, create the protocol params file with:

```bash
./scripts/query-protocol-parameters.sh
```

To use the transactions, first test datums and wallets must be created.

## Test Wallet Creation

Run:

```bash
./scripts/wallets/make-all-wallets.sh
```

## Environment Variable Setup

To setup the proper flags and socket variables for the test transactions, one must source the appropiate environment variables.

### ⚠️ Warning
To use the local testnet envars, the file must be modified to point to your local testnet location.

- Local testnet: `source scripts/envars/local-testnet.envars`
- Shared testnet: `source scripts/envars/testnet-env.envars`
- Mainnet: `source scripts/envars/mainnet-env.envars`

Now, one can run the `scripts/happy-path/` transactions.

# Testing

### ⚠️ Prerequistes
**Follow all the setup steps in the `Example Transaction` section, before continuing.**

There is a single test script, which performs a number of integration tests functions.

To execute the integration test, run:

```bash
./scripts/tests/mint-burn.sh
```
