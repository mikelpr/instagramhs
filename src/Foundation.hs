{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell   #-}
{-# LANGUAGE TypeFamilies      #-}
{-# LANGUAGE ViewPatterns      #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}
module Foundation where

import Yesod.Core
import Data.IORef
import Data.IntMap.Strict
import Data.ByteString
import Data.Text

import GHC.Generics
import Data.Aeson (ToJSON(..), Value(..), object, (.=), (.:), FromJSON(..), withObject)

data PostMeta = PostMeta {
  caption:: Maybe Text,
  likes:: Int
} deriving (Generic, Eq, Show, ToJSON)

data CachedPost = CachedPost {
  imagedata:: ByteString,
  meta:: PostMeta
}

newtype App = App {cache:: IORef (IntMap CachedPost)}

mkYesodData "App" $(parseRoutesFile "routes")

instance Yesod App
