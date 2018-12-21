{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}
import Application () -- for YesodDispatch instance
import Foundation
import Yesod.Core

import Network.HTTP.Simple
import Data.IntMap.Strict (empty)
import Data.IORef
import Data.Text(Text,unpack)
import Data.Aeson
import Data.Aeson.Types
import GHC.Generics
import qualified Data.IntMap.Strict as IntMap

data ParsePost = ParsePost {
  _displayUrl:: Text,
  _caption:: Maybe Text,
  _likes:: Int,
  _id:: Text
} deriving (Generic, Show)

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

mkrq :: Request -> Request
mkrq requrl =
  setRequestHeaders [("cookie","sessionid=1083240%3AHwonWAItrpChKp%3A15;")] $
  setRequestQueryString [("__a", Just "1")] requrl

mediaparser:: Value -> Parser [ParsePost]
mediaparser = withObject "graph" $ \o -> do
    graph <- o .: "graphql"
    user <- graph .: "user"
    mediaEdge <- user .: "edge_owner_to_timeline_media"
    mediaEdge .: "edges"

cacheposts:: [ParsePost] -> IO [IntMap.IntMap ParsedPost]
cacheposts pp = do
  hackish <- newIORef IntMap.empty
  sequence $map (\post -> do
      let rq = parseRequest_ $unpack $_displayUrl post
      imgresponse <- httpBS $mkrq rq
      let bodybs = getResponseBody imgresponse
      let nupost = ParsedPost (_displayUrl post) (_caption post) (_likes post)
      liftIO (atomicModifyIORef' hackish (\ma -> (IntMap.insert (read $unpack $_id post) nupost ma, ma)))
    ) pp

main :: IO ()
main = do
  mem <- newIORef empty
  response <- httpLBS $mkrq "https://instagram.com/rollingstonemx"
  --let bodybs = getResponseBody response
  --let bodydec = decode bodybs
  let bodydec = decode $ getResponseBody response
  case parseMaybe mediaparser =<< bodydec of
    Just posts -> do
      nuposts <- liftIO $cacheposts posts
      liftIO $atomicModifyIORef' mem (const (last nuposts, ()))
    Nothing -> fail "failed parsing instagram"
  warp 3000 App{postCache = mem}
