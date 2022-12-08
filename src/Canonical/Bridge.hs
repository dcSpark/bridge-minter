{-# LANGUAGE NoImplicitPrelude #-}

module Canonical.Bridge where

import           Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV2)
import           Codec.Serialise
import qualified Data.ByteString.Lazy as LB
import qualified Data.ByteString.Short as SBS
import           Plutus.V1.Ledger.Scripts
import           Plutus.V1.Ledger.Value
import qualified Cardano.Api.Shelley as Shelly
import qualified Data.ByteString.Short as BSS
import qualified Data.ByteString.Lazy as BSL
import           PlutusTx
import           PlutusTx.Prelude hiding (Semigroup (..), unless)
import qualified PlutusTx.AssocMap as M

data Action = A_Mint [TokenName] | A_Burn

data BridgeConfig = BridgeConfig
  { bcErc721Id               :: BuiltinByteString
  , bcPermissionNftPolicyId  :: CurrencySymbol
  , bcPermissionNftTokenName :: TokenName
  }

data BridgeTxOut = BridgeTxOut
  { bTxOutAddress         :: BuiltinData
  , bTxOutValue           :: Value
  , bTxOutDatum           :: BuiltinData
  , bTxOutReferenceScript :: BuiltinData
  }

data BridgeTxInInfo = BridgeTxInInfo
  { bTxInInfoOutRef           :: BuiltinData
  , bTxInInfoResolved         :: BridgeTxOut
  }

data BridgeTxInfo = BridgeTxInfo
  { bTxInfoInputs             :: [BridgeTxInInfo]
  , bTxInfoReferenceInputs    :: BuiltinData
  , bTxInfoOutputs            :: BuiltinData
  , bTxInfoFee                :: BuiltinData
  , bTxInfoMint               :: Value
  , bTxInfoDCert              :: BuiltinData
  , bTxInfoWdrl               :: BuiltinData
  , bTxInfoValidRange         :: BuiltinData
  , bTxInfoSignatories        :: BuiltinData
  , bTxInfoRedeemers          :: BuiltinData
  , bTxInfoData               :: BuiltinData
  , bTxInfoId                 :: BuiltinData
  }

data BridgeScriptPurpose
    = BMinting CurrencySymbol

data BridgeScriptContext = BridgeScriptContext
  { bScriptContextTxInfo  :: BridgeTxInfo
  , bScriptContextPurpose :: BridgeScriptPurpose
  }

unstableMakeIsData ''BridgeTxOut
unstableMakeIsData ''BridgeTxInInfo
unstableMakeIsData ''BridgeTxInfo
unstableMakeIsData ''BridgeScriptPurpose
unstableMakeIsData ''BridgeScriptContext
unstableMakeIsData ''Action
makeLift ''BridgeConfig

-- TODO
-- write helper for testing if NFT is being spent
hasPermissionNft :: CurrencySymbol -> TokenName -> BridgeTxInInfo -> Bool
hasPermissionNft = error ()

-- Verify that only 1 token is minted for each token name
mkPolicy :: BridgeConfig -> Action -> BridgeScriptContext -> Bool
mkPolicy BridgeConfig {..} action BridgeScriptContext
  { bScriptContextTxInfo = BridgeTxInfo {..}
  , bScriptContextPurpose = BMinting theCurrencySymbol
  } =
  let
    hasNft :: Bool
    !hasNft = case filter (hasPermissionNft bcPermissionNftPolicyId bcPermissionNftTokenName) bTxInfoInputs of
      [] -> traceError "No permission nft"
      [_] -> True
      _ -> traceError "Impossible. Multiple permission nfts"

  in hasNft
  && case action of
    A_Burn ->
      let
        counts :: [Integer]
        !counts = case M.lookup theCurrencySymbol (getValue bTxInfoMint) of
          Nothing -> traceError "Impossible!"
          Just m  -> map snd (M.toList m)

        allCountsLessThanZero :: Bool
        !allCountsLessThanZero = all (<0) counts

      in traceIfFalse "Burning but some counts are greater than zero" allCountsLessThanZero

    A_Mint _ ->
      let
        correctAmountIsMinted :: Bool
        !correctAmountIsMinted = error ()

      in correctAmountIsMinted

-------------------------------------------------------------------------------
-- Entry Points
-------------------------------------------------------------------------------
wrappedPolicy :: BridgeConfig -> BuiltinData -> BuiltinData -> ()
wrappedPolicy config x y = check (mkPolicy config (unsafeFromBuiltinData x) (unsafeFromBuiltinData y))

validatorHash :: Validator -> ValidatorHash
validatorHash = ValidatorHash . getScriptHash . scriptHash . getValidator

scriptHash :: Script -> ScriptHash
scriptHash =
    ScriptHash
    . toBuiltin
    . Shelly.serialiseToRawBytes
    . Shelly.hashScript
    . toCardanoApiScript

toCardanoApiScript :: Script -> Shelly.Script Shelly.PlutusScriptV2
toCardanoApiScript
  = Shelly.PlutusScript Shelly.PlutusScriptV2
  . Shelly.PlutusScriptSerialised
  . BSS.toShort
  . BSL.toStrict
  . serialise

mintingPolicyHash :: MintingPolicy -> MintingPolicyHash
mintingPolicyHash
  = MintingPolicyHash
  . getScriptHash
  . scriptHash
  . getValidator
  . Validator
  . getMintingPolicy

policy :: BridgeConfig -> MintingPolicy
policy config = mkMintingPolicyScript $
  $$(compile [|| wrappedPolicy ||])
  `applyCode`
  liftCode config

plutusScript :: BridgeConfig -> Script
plutusScript = unMintingPolicyScript . policy

validator :: BridgeConfig -> Validator
validator = Validator . plutusScript

bridgePolicyId :: BridgeConfig -> CurrencySymbol
bridgePolicyId = mpsSymbol . mintingPolicyHash . policy

scriptAsCbor :: BridgeConfig -> LB.ByteString
scriptAsCbor = serialise . validator

bridge :: BridgeConfig -> PlutusScript PlutusScriptV2
bridge
  = PlutusScriptSerialised
  . SBS.toShort
  . LB.toStrict
  . scriptAsCbor
