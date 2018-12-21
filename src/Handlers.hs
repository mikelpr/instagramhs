{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}
module Handlers where

import Foundation
import Yesod.Core
import qualified Network.HTTP.Types.Status as Status
import qualified Data.IntMap.Strict as IntMap
import Data.IORef(readIORef)

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