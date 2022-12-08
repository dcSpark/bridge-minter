set -eux

thisDir=$(dirname "$0")
baseDir=$thisDir/../
tempDir=$baseDir/../temp

detected=false

"$baseDir/happy-path/mint-1.sh" || {
    detected=true
}

if [ $detected == false ]; then
  echo "Failed to prevent missing permission nft minting"
  exit 1
fi

$baseDir/minting/mint-0-policy.sh
$baseDir/wait/until-next-block.sh

$baseDir/happy-path/mint-1.sh
$baseDir/wait/until-next-block.sh

$baseDir/happy-path/burn.sh
$baseDir/wait/until-next-block.sh
