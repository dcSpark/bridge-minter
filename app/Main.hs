{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main where
import           Cardano.Api
import           Canonical.Bridge
import           Options.Generic

data Options = Options
  { scriptOutputFile   :: FilePath
  , policyIdOutputFile :: FilePath
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

  result <- writeFileTextEnvelope scriptOutputFile Nothing (bridge config)
  case result of
    Left err -> print $ displayError err
    Right () -> putStrLn $ "wrote validator to file " ++ scriptOutputFile

  writeFile policyIdOutputFile $ show $ bridgePolicyId config
