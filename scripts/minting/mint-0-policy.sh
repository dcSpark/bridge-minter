./scripts/minting/test-mint-tx.sh \
  $(cardano-cli-balance-fixer collateral --address $(cat ~/$BLOCKCHAIN_PREFIX/user0.addr) $BLOCKCHAIN) \
   scripts/test-policies/test-policy-0.plutus \
   $(cat scripts/test-policies/test-policy-0-id.txt) 544F4B454E 1
