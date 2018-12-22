{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}

import Prelude hiding(writeFile)
import Network.HTTP.Simple
import Data.ByteString.Lazy(writeFile)
import Data.IntMap.Strict (empty)
import Data.IORef
import Data.Text(Text,unpack)
import Data.Aeson
import Data.Aeson.Types
import GHC.Generics
import Control.Monad
import System.Directory(getCurrentDirectory)
--import Data.Aeson (ToJSON(..), Value(..), object, (.=), (.:), FromJSON(..), withObject)
import qualified Data.IntMap.Strict as IntMap

data ParsePost = ParsePost {
  _displayUrl:: Text,
  _caption:: Maybe Text,
  _likes:: Int,
  _id:: Text
} deriving (Generic, Show)

data ParsedPost = ParsedPost {
  caption:: Maybe Text,
  likes:: Int,
  displayUrl:: Text
} deriving (Generic, Show, ToJSON)

instance FromJSON ParsePost where
  parseJSON = withObject "node" $ \o -> do
    node <- o .: "node"
    _id <- node .: "id"
    _displayUrl <- node .: "display_url"
    _caption <- do 
      edge1 <- node .: "edge_media_to_caption"
      edge2 <- edge1 .: "edges"
      case edge2 of
        [x] -> do
          edge3 <- x .: "node"
          edge3 .: "text"
        [] -> pure Nothing
    _likes <- do
      edge1 <- node .: "edge_liked_by"
      edge1 .: "count"
    return ParsePost{..}

mediaparser:: Value -> Parser [ParsePost]
mediaparser = withObject "graph" $ \o -> do
    graph <- o .: "graphql"
    user <- graph .: "user"
    mediaEdge <- user .: "edge_owner_to_timeline_media"
    mediaEdge .: "edges"

mkrq :: Request -> Request
mkrq requrl =
  setRequestHeaders [("cookie","sessionid=1083240%3AHwonWAItrpChKp%3A15;")] $
  setRequestQueryString [("__a", Just "1")] requrl

main :: IO ()
main = do
  putStrLn "Refreshing instagram latest posts' metadata"
  pwd <- getCurrentDirectory
  putStrLn $ "(PWD: " ++ pwd ++ ")"
  response <- httpLBS $mkrq "https://instagram.com/rollingstonemx"
  let code = getResponseStatusCode response
  case code of
    200 -> do
      let bodydec = decode $ getResponseBody response
      case parseMaybe mediaparser =<< bodydec of
        Just posts -> do
          mapM_
            (\x -> writeFile (unpack (_id x)) $
              encode $ ParsedPost (_caption x) (_likes x) (_displayUrl x))
            posts
          putStrLn "Done."
        Nothing -> fail "failed parsing instagram return data."
    _ -> fail$ "bad response code " ++ show code
