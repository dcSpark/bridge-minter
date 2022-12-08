set -eux
thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

$baseDir/core/mint.sh \
  $(cat ~/$BLOCKCHAIN_PREFIX/user0.addr) \
  ~/$BLOCKCHAIN_PREFIX/user0.skey \
  $baseDir/redeemers/mint1.json
