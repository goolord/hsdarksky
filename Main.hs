{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}

module Main where

import Network.Wreq
import Text.Toml
import Control.Lens
import Data.Text (Text)
import Data.Either
import Data.HashMap.Lazy
import Text.Megaparsec.Error (errorBundlePretty)
import Data.Hashable
import Data.Aeson
import Data.Aeson.Lens
import System.Environment
import qualified Data.ByteString.Lazy as BSL
import qualified Data.Text as T
import qualified Data.Text.IO as T
-- import qualified Data.Aeson as AE

main :: IO ()
main = do 
  [path] <- getArgs
  txt <- T.readFile path
  let config :: Table
      config = case parseTomlDoc "" txt of
        Left err -> error (errorBundlePretty err)
        Right table -> table
  let opts = defaults & param "units" .~ ["auto"]
  r <- getWith opts
        $ "https://api.darksky.net/forecast/" 
        <> T.unpack (vString (wtr config "api")) <> "/" 
        <> show (vDouble (wtr config "latitude")) <> "," 
        <> show (vDouble (wtr config "longitude"))
  let temp :: Double
      (Just (Success temp)) = fromJSON <$> r ^? responseBody . key "currently" . key "temperature"
  let icon' :: Text
      (Just (Success icon')) = fromJSON <$> r ^? responseBody . key "currently" . key "icon"
  let icon :: Text
      icon = iconEnc (vBool (opt config "nerdfont")) icon'
  T.putStr $ icon <> " " <> tempEnc (vBool (opt config "round")) temp <> "°"
  pure ()

tempEnc :: Bool -> Double -> Text
tempEnc True  temp = tshow $ (round temp :: Int)
tempEnc False temp = tshow temp

iconEnc :: Bool -> Text -> Text
iconEnc True "clear-day"           = "\61829" --  
iconEnc True "clear-night"         = "\61830" --  
iconEnc True "rain"                = "\61673" --  
iconEnc True "snow"                = "\64151" -- 流
iconEnc True "sleet"               = "\58285" --  
iconEnc True "wind"                = "\61912" --  
iconEnc True "fog"                 = "\64144" -- 敖 
iconEnc True "cloudy"              = "\58130" --  
iconEnc True "partly-cloudy-day"   = "\64148" -- 杖 
iconEnc True "partly-cloudy-night" = "\58233" -- 
iconEnc _ _  = ""

wtr :: Table -> Text -> Node
wtr hm b = table ! b
  where (VTable table) = hm ! "weather"

opt :: Table -> Text -> Node
opt hm b = table ! b
  where (VTable table) = hm ! "options"

vString :: Node -> Text
vString (VString s) = s
vString x = error $ "expecting string, got " <> show x

vDouble :: Node -> Double
vDouble (VFloat d) = d
vDouble x = error $ "expecting double, got " <> show x

vBool :: Node -> Bool
vBool (VBoolean b) = b
vBool x = error $ "expecting bool, got " <> show x

tshow :: Show a => a -> Text
tshow = T.pack . show
