{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}
module Handlers where

import Foundation
import Yesod.Core
import Network.HTTP.Simple
import qualified Network.HTTP.Types.Status as Status
import qualified Data.IntMap.Strict as IntMap
import qualified Data.ByteString.Char8 as S8
import qualified Data.ByteString as BS
import Data.IORef
import Data.Text(Text,unpack)
import Data.Conduit
import Data.Aeson
import Data.Aeson.Types
import GHC.Generics

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

mediaparser:: Value -> Parser [ParsePost]
mediaparser = withObject "graph" $ \o -> do
    graph <- o .: "graphql"
    user <- graph .: "user"
    mediaEdge <- user .: "edge_owner_to_timeline_media"
    mediaEdge .: "edges"

liftCache = do
  yesod <- getYesod
  liftIO (readIORef $postCache yesod)

getCachedPostsR:: Handler TypedContent
getCachedPostsR = do
  cached <- liftCache
  sendStatusJSON Status.ok200 cached

getMetaR:: Int -> Handler RepJson
getMetaR int = do
  cached <- liftCache
  case cached IntMap.!? int of
    Just a -> sendStatusJSON Status.ok200 a
    Nothing -> sendResponseStatus Status.notFound404 ()

--getImageR:: Int -> Handler TypedContent
--getImageR int = do
--  cached <- liftCache
--  case cached IntMap.!? int of
--    Just a -> redirect 
--    Nothing -> sendResponseStatus Status.notFound404 ()

mkrq :: Request -> Request
mkrq requrl =
  setRequestHeaders [("cookie","sessionid=1083240%3AHwonWAItrpChKp%3A15;")] $
  setRequestQueryString [("__a", Just "1")] requrl

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

postRefreshR:: Handler ()
postRefreshR = do
  yesod <- getYesod
  response <- httpLBS $mkrq "https://instagram.com/rollingstonemx"
  --let bodybs = getResponseBody response
  --let bodydec = decode bodybs
  let bodydec = decode $ getResponseBody response
  case parseMaybe mediaparser =<< bodydec of
    --Just ppost -> liftIO $print ppost
    --Just posts -> liftIO $cacheposts posts
    Just posts -> do
      nuposts <- liftIO $cacheposts posts
      liftIO $atomicModifyIORef' (postCache yesod) (const (last nuposts, ()))
    Nothing -> liftIO $print $getResponseStatus response
    --Nothing -> liftIO $print bodydec
  --liftIO $atomicModifyIORef' (cache yesod) (\intmap -> (IntMap.insert  set, set))