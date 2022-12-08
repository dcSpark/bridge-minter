set -eux

thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

mkdir -p $tempDir

minterAddress=$(cat ~/$BLOCKCHAIN_PREFIX/user0.addr)
signingKey=~/$BLOCKCHAIN_PREFIX/user0.skey
bridgeMinterRedeemer=$baseDir/redeemers/mint1.json
tokenName=1234

bodyFile=$tempDir/sell-tx-body.01
outFile=$tempDir/sell-tx.01
changeOutput=$(cardano-cli-balance-fixer change --address $minterAddress $BLOCKCHAIN)

bridgeMinterId=$(cat $baseDir/../assets/bridge-policy-id.txt)
bridgeMinterFile=$baseDir/../assets/bridge.plutus

extraOutput=""
if [ "$changeOutput" != "" ];then
  extraOutput="+ $changeOutput"
fi

mintValue="2 $bridgeMinterId.$tokenName"

cardano-cli transaction build \
    --babbage-era \
    $BLOCKCHAIN \
    $(cardano-cli-balance-fixer input --address $minterAddress $BLOCKCHAIN) \
    --tx-in-collateral $(cardano-cli-balance-fixer collateral --address $minterAddress $BLOCKCHAIN) \
    --tx-out "$minterAddress + 2137884 lovelace + $mintValue $extraOutput" \
    --change-address $minterAddress \
    --protocol-params-file scripts/$BLOCKCHAIN_PREFIX/protocol-parameters.json \
    --mint "$mintValue" \
    --mint-script-file $bridgeMinterFile \
    --mint-redeemer-file $bridgeMinterRedeemer \
    --out-file $bodyFile

echo "saved transaction to $bodyFile"

cardano-cli transaction sign \
    --tx-body-file $bodyFile \
    --signing-key-file $signingKey \
    $BLOCKCHAIN \
    --out-file $outFile

echo "signed transaction and saved as $outFile"

cardano-cli transaction submit \
 $BLOCKCHAIN \
 --tx-file $outFile

echo "submitted transaction"

echo
