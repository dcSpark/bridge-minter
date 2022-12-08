{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main where
import           Cardano.Api
import           Canonical.Bridge
import           Options.Generic
import           Plutus.V1.Ledger.Value
import           PlutusTx.Builtins
import           Data.String

instance ParseField TokenName where
  parseField x y z w = fromString <$> parseField x y z w
  readField = fromString <$> readField

instance ParseFields TokenName where
  parseFields x y z w = fromString <$> parseFields x y z w

instance ParseRecord TokenName where
  parseRecord = fromString <$> parseRecord

instance ParseField CurrencySymbol where
  parseField x y z w = fromString <$> parseField x y z w
  readField = fromString <$> readField

instance ParseFields CurrencySymbol where
  parseFields x y z w = fromString <$> parseFields x y z w

instance ParseRecord CurrencySymbol where
  parseRecord = fromString <$> parseRecord

instance ParseField BuiltinByteString where
  parseField x y z w = fromString <$> parseField x y z w
  readField = fromString <$> readField

instance ParseFields BuiltinByteString where
  parseFields x y z w = fromString <$> parseFields x y z w

instance ParseRecord BuiltinByteString where
  parseRecord = fromString <$> parseRecord

data Options = Options
  { scriptOutputFile         :: FilePath
  , policyIdOutputFile       :: FilePath
  , erc721Id                 :: BuiltinByteString
  , permissionNftPolicyId    :: CurrencySymbol
  , permissionNftTokenName   :: TokenName
  }
  deriving(Generic)

fieldModifier :: Modifiers
fieldModifier = lispCaseModifiers
  { fieldNameModifier = fieldNameModifier lispCaseModifiers
  }

instance ParseRecord Options where
  parseRecord = parseRecordWithModifiers fieldModifier

main :: IO ()
main = run =<< getRecord "Bridge Compiler"

run :: Options -> IO ()
run Options {..} = do
  let
    config = BridgeConfig
      { bcErc721Id               = erc721Id
      , bcPermissionNftPolicyId  = permissionNftPolicyId
      , bcPermissionNftTokenName = permissionNftTokenName
      }

  result <- writeFileTextEnvelope scriptOutputFile Nothing (bridge config)
  case result of
    Left err -> print $ displayError err
    Right () -> putStrLn $ "wrote validator to file " ++ scriptOutputFile

  writeFile policyIdOutputFile $ show $ bridgePolicyId config
