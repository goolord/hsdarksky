{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Network.Wreq
import Control.Lens
import Data.Text (Text)
import Data.Aeson
import Data.Aeson.Lens
import System.Environment
import qualified Data.Text as T
import qualified Data.Text.IO as T

main :: IO ()
main = do 
  [api, lat, long] <- getArgs
  let opts = defaults & param "units" .~ ["auto"]
  r <- getWith opts
        $ "https://api.darksky.net/forecast/"
        <> api <> "/"
        <> lat <> ","
        <> long
  let temp :: Double
      (Just (Success temp)) = fromJSON <$> r ^? responseBody . key "currently" . key "temperature"
  let icon' :: Text
      (Just (Success icon')) = fromJSON <$> r ^? responseBody . key "currently" . key "icon"
  let icon :: Text
      icon = iconEnc icon'
  T.putStr $ icon <> " " <> tempEnc temp <> "°"
  pure ()
{-# INLINE main #-}

tempEnc :: Double -> Text
tempEnc temp = tshow $ (round temp :: Int)
{-# INLINE tempEnc #-}

iconEnc :: Text -> Text
iconEnc "clear-day"           = "\61829" --  
iconEnc "clear-night"         = "\61830" --  
iconEnc "rain"                = "\61673" --  
iconEnc "snow"                = "\64151" -- 流
iconEnc "sleet"               = "\58285" --  
iconEnc "wind"                = "\61912" --  
iconEnc "fog"                 = "\64144" -- 敖
iconEnc "cloudy"              = "\58130" --  
iconEnc "partly-cloudy-day"   = "\64148" -- 杖
iconEnc "partly-cloudy-night" = "\58233" --  
iconEnc _ = ""
{-# INLINE iconEnc #-}

tshow :: Show a => a -> Text
tshow = T.pack . show
{-# SPECIALIZE 
  tshow :: Double -> Text #-}
