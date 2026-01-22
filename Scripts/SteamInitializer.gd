extends Node

var initialized := false

func _ready():
	if initialized:
		return
	print("Steam Initialized:", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	initialized = true
