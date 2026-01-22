extends Node

var OWNED: bool = false
var ONLINE: bool = false
var STEAM_ID : int = 0
var STEAM_NAME : String = ""

var initialized : bool = false
var LOBBY_ID: int = 0
var LOBBY_MEMBERS =[]
var LOBBY_INVITE_ARG: bool = false



func _ready():
	if initialized:
		return
	print("Steam Initialized:", Steam.steamInit(480, true))
	
	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()
	STEAM_NAME = Steam.getPersonaName()
	OWNED = Steam.isSubscribed()
	
	Steam.initRelayNetworkAccess()
	initialized = true
	
	if OWNED == false:
		get_tree().quit()

func _process(_delta: float) -> void:
	Steam.run_callbacks()
