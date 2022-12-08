#!/usr/bin/env bash

set -eux
mkdir -p scripts/temp/
mkdir -p ~/$BLOCKCHAIN_PREFIX
./scripts/wallets/make-wallet-and-pkh.sh user0
