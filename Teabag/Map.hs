module Teabag.Map where

import Teabag.Global

import SFML.Graphics

data Tiledef =
	T_ { name :: String,
		  col :: Color,
          blocking :: Bool,
          collMap :: Bool }
	deriving (Show, Eq)

data Map =
	M_ { tiledefs :: [Tiledef] }

loadMap :: String -> IO Map
loadMap mapname = do
	optsFile <- loadFile $ teaMapFile mapname
	tiles <- getAllOptions optsFile "tile"
	print tiles
	tdefs <- mapM createTileDef tiles
	print tdefs
	return (M_ tdefs)

createTileDef :: Monad m => [String] -> m Tiledef
createTileDef [r', g', b', name', coll, collMap'] = 
	return (T_ name' (Color (read r') (read g') (read b') 0) (toBool coll) (toBool collMap'))
	where
	toBool :: String -> Bool
	toBool "0" = False
	toBool _ = True