-- stack --resolver lts-13.0 script
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE DeriveAnyClass    #-}

import Network.HTTP.Simple
import Data.Text(Text,unpack)
import Data.Aeson
import Data.Aeson.Types
import GHC.Generics
import System.Directory(getCurrentDirectory)
import System.Environment
import System.IO(hPutStrLn,stderr)
import qualified Data.ByteString.Char8 as BS8
import qualified Data.ByteString.Lazy as BSL

data PostData = PostData {
  caption:: Maybe Text,
  likes:: Int,
  displayUrl:: Text
} deriving (Generic, Show, ToJSON)
newtype ParsePost = ParsePost (Text, PostData) -- (id, data)

instance FromJSON ParsePost where
  parseJSON = withObject "node" $ \o -> do
    node <- o .: "node"
    postId <- node .: "id"
    displayUrl <- node .: "display_url"
    caption <- do 
      edge1 <- node .: "edge_media_to_caption"
      edge2 <- edge1 .: "edges"
      case edge2 of
        [x] -> do
          edge3 <- x .: "node"
          edge3 .: "text"
        [] -> pure Nothing
    likes <- do
      edge1 <- node .: "edge_liked_by"
      edge1 .: "count"
    return $ ParsePost (postId, PostData{..})

userParser:: Value -> Parser [ParsePost]
userParser = withObject "graph" $ \o -> do
  graph <- o .: "graphql"
  user <- graph .: "user"
  mediaEdge <- user .: "edge_owner_to_timeline_media"
  mediaEdge .: "edges"

main :: IO ()
main = do
  myname <- getProgName
  args <- getArgs
  sessid <- getEnv "_IG_SESSION_ID"
  pwd <- getCurrentDirectory
  if length args /= 2 then fail $ "Usage: " ++ myname ++ " username_to_scrap outfileOr-"
  else do
    let [user, outfile] = args
    logStrLn $ "Refreshing instagram latest posts' metadata for user " ++ user
    logStrLn $ "(PWD: " ++ pwd ++ ")"
    let mkrq requrl = setRequestHeaders [("cookie", BS8.pack $ "sessionid=" ++ sessid ++ ";")] $
                      setRequestQueryString [("__a", Just "1")] requrl
    response <- httpJSON $ mkrq (parseRequest_ $ "https://instagram.com/" ++ user)
    let code = getResponseStatusCode response
    case code of
      200 ->
        case parseMaybe userParser =<< getResponseBody response of
          Just posts ->
            if outfile == "-" then BSL.putStr $ encode outmap
            else do
              encodeFile outfile outmap
              logStrLn "Done."
            where outmap = map 
                            (\(ParsePost (x, y)) -> (x, y))
                            posts
          Nothing -> fail "failed parsing instagram return data."
      _ -> fail $ "bad response code " ++ show code
    where logStrLn = hPutStrLn stderr
