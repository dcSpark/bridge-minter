{-# LANGUAGE NoImplicitPrelude #-}

module Canonical.Bridge where

import           Cardano.Api.Shelley (PlutusScript (..), PlutusScriptV2)
import           Codec.Serialise
import qualified Data.ByteString.Lazy as LB
import qualified Data.ByteString.Short as SBS
import           Plutus.V2.Ledger.Contexts
import           Plutus.V1.Ledger.Scripts
-- import           Plutus.V1.Ledger.Crypto
-- import           Plutus.V2.Ledger.Tx
import           Plutus.V1.Ledger.Value
import qualified Cardano.Api.Shelley as Shelly
import qualified Data.ByteString.Short as BSS
import qualified Data.ByteString.Lazy as BSL
import           PlutusTx
import           PlutusTx.Prelude hiding (Semigroup (..), unless)

data Action = A_Mint TokenName | A_Burn
data BridgeConfig = BridgeConfig
  { bcErc721Id               :: BuiltinByteString
  , bcPermissionNftPolicyId  :: CurrencySymbol
  , bcPermissionNftTokenName :: TokenName
  }

unstableMakeIsData ''Action
makeLift ''BridgeConfig

mkPolicy :: BridgeConfig -> Action -> ScriptContext -> Bool
mkPolicy BridgeConfig {} action ScriptContext {} = case action of
  A_Burn -> error ()
  A_Mint _ -> error ()

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
