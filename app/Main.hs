import Application () -- for YesodDispatch instance
import Foundation
import Yesod.Core

import Data.IntMap.Strict (empty)
import Data.IORef (newIORef)

main :: IO ()
main = do
  mem <- newIORef empty
  warp 3000 App{postCache = mem}
