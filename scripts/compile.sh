set -eu
thisDir=$(dirname "$0")
mainDir=$thisDir/..
tempDir=$mainDir/temp

(
cd $mainDir
cabal run bridge-sc -- --script-output-file=assets/bridge.plutus --policy-id-output-file=assets/bridge-policy-id.txt
)
