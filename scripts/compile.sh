set -eu
thisDir=$(dirname "$0")
mainDir=$thisDir/..
tempDir=$mainDir/temp

(
cd $mainDir
cabal run bridge-sc -- \
  --script-output-file=assets/bridge.plutus \
  --policy-id-output-file=assets/bridge-policy-id.txt \
  --permission-nft-policy-id=ce8822885d18e7d304ef0248af49359d687a94f0e3635eea14c6154e \
  --permission-nft-token-name=TOKEN \
  --erc721-id=a37767c537bbf908aa2bf5abf49ef3fd67e749cbca3225d31bd166e0
)
