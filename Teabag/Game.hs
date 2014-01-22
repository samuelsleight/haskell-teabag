module Teabag.Game (
	EventType(
		TeaClosed,
		TeaResized,
		TeaLostFocus,
		TeaGainedFocus,
		TeaTextEntered,
		TeaKeyPressed,
		TeaKeyReleased,
		TeaMouseWheelMoved,
		TeaMouseButtonPressed,
		TeaMouseButtonReleased,
		TeaMouseMoved,
		TeaMouseEntered,
		TeaMouseLeft,
		TeaJoystickButtonPressed,
		TeaJoystickButtonReleased,
		TeaJoystickMoved,
		TeaJoystickConnected,
		TeaJoystickDisconnected
	),

	Game(G_),
	
	teaInit,
	teaBindEvent,
	teaRun,
	teaClose,
	teaDestroy
) where

import Teabag.Global

import Control.Monad

import SFML.Window
import SFML.Graphics

data EventType =
	  TeaClosed 
	| TeaResized
	| TeaLostFocus
	| TeaGainedFocus
	| TeaTextEntered
	| TeaKeyPressed
	| TeaKeyReleased
	| TeaMouseWheelMoved
	| TeaMouseButtonPressed
	| TeaMouseButtonReleased
	| TeaMouseMoved
	| TeaMouseEntered
	| TeaMouseLeft
	| TeaJoystickButtonPressed
	| TeaJoystickButtonReleased
	| TeaJoystickMoved
	| TeaJoystickConnected
	| TeaJoystickDisconnected
	deriving (Eq, Show)

data Game = 
	G_ RenderWindow [(EventType, [SFEvent -> Game -> IO ()])]

getEvtType :: SFEvent -> EventType
getEvtType e = case e of
	SFEvtClosed -> TeaClosed
	SFEvtResized{} -> TeaResized
	SFEvtLostFocus -> TeaLostFocus
	SFEvtGainedFocus -> TeaGainedFocus
	SFEvtTextEntered{} -> TeaTextEntered
	SFEvtKeyPressed{} -> TeaKeyPressed
	SFEvtKeyReleased{} -> TeaKeyReleased
	SFEvtMouseWheelMoved{} -> TeaMouseWheelMoved
	SFEvtMouseButtonPressed{} -> TeaMouseButtonPressed
	SFEvtMouseButtonReleased{} -> TeaMouseButtonReleased
	SFEvtMouseMoved{} -> TeaMouseMoved
	SFEvtMouseEntered -> TeaMouseEntered
	SFEvtMouseLeft -> TeaMouseLeft
	SFEvtJoystickButtonPressed{} -> TeaJoystickButtonPressed
	SFEvtJoystickButtonReleased{} -> TeaJoystickButtonReleased
	SFEvtJoystickMoved{} -> TeaJoystickMoved
	SFEvtJoystickConnected{} -> TeaJoystickConnected 
	SFEvtJoystickDisconnected{} -> TeaJoystickDisconnected
 
teaInit :: IO Game
teaInit = do
	dataFile <- loadFile teaMainFile
	name <- liftM unwords $ getOptions dataFile "name"
	[w, h] <- getOptions dataFile "wind"
	wnd <- createRenderWindow (VideoMode (read w) (read h) 32) name [SFDefaultStyle] Nothing
	return $ G_ wnd []

addCallback :: [(EventType, [SFEvent -> Game -> IO ()])] -> EventType -> (SFEvent -> Game -> IO ()) -> [(EventType, [SFEvent -> Game -> IO ()])]
addCallback [] evtType evtCall = [(evtType, [evtCall])]
addCallback ((t, ls):evts) evtType evtCall = 
	if t == evtType then
		((t, evtCall:ls):evts)
	else
		((t, ls):(addCallback evts evtType evtCall))

teaBindEvent :: Monad m => Game -> EventType -> (SFEvent -> Game -> IO ()) -> m Game
teaBindEvent (G_ wnd evts) evtType evtCall = return (G_ wnd (addCallback evts evtType evtCall))

callFuncs :: SFEvent -> Game -> [SFEvent -> Game -> IO ()] -> IO Game
callFuncs evt game [] = runLoop game
callFuncs evt game (f:ls) = f evt game >> callFuncs evt game ls

findAndCallFuncs :: EventType -> SFEvent -> Game -> [(EventType, [SFEvent -> Game -> IO ()])] -> IO Game
findAndCallFuncs evtType evt game [] = runLoop game
findAndCallFuncs evtType evt game ((t,fs):evts) = 
	if t == evtType then
		callFuncs evt game fs
	else 
		findAndCallFuncs evtType evt game evts

renderWindow :: Game -> IO Game
renderWindow game@(G_ wnd evts) = do
	clearRenderWindow wnd black
	display wnd
	teaRun game

runLoop :: Game -> IO Game
runLoop game@(G_ wnd evts) = do
	evt <- pollEvent wnd
	case evt of
		Just e -> findAndCallFuncs (getEvtType e) e game evts
		Nothing -> renderWindow game

teaRun :: Game -> IO Game
teaRun game@(G_ wnd evts) = do
	running <- isWindowOpen wnd
	(if not running then return else runLoop) game
	
teaClose :: Game -> IO ()
teaClose (G_ wnd evts) = close wnd

teaDestroy :: Game -> IO ()
teaDestroy (G_ wnd evts) = destroy wnd