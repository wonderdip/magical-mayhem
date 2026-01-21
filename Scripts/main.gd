extends Node2D

var lobby_id: int = 0
var peer : SteamMultiplayerPeer
@export var player_scene : PackedScene
var is_host : bool = true
var is_joining: bool
var private: bool = false
var public: bool = true


@onready var host_button: Button = $UI/HostButton
@onready var join_button: Button = $UI/JoinButton
@onready var id_prompt: LineEdit = $UI/IdPrompt
@onready var name_prompt: LineEdit = $UI/NamePrompt
@onready var server_visibility: OptionButton = $UI/ServerVisibility
@onready var ui: Control = $UI

func _ready() -> void:
	print("Steam Initialized: ", Steam.steamInit(480, true))
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)

func host_lobby():
	if private:
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PRIVATE, 16)
	elif public:
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)
		
	is_host = true
	
	@warning_ignore("shadowed_variable")
func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		Steam.setLobbyData(lobby_id, "name", name_prompt.text)
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		_add_player()
		
		print("Lobby Created, lobby id: ", lobby_id, "Lobby Private: ", private, "Lobby Public: ", public)
		ui.hide()
		
	@warning_ignore("shadowed_variable")
func join_lobby(lobby_id: int):
	is_joining = true
	Steam.joinLobby(lobby_id)
	
	@warning_ignore("shadowed_variable")
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int):
	
	if !is_joining:
		return
		
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	
	is_joining = false
	
func _add_player(id: int = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	
func _remove_player(id: int):
	if not self.has_node(str(id)):
		return
	
	self.get_node(str(id)).queue_free()

func _on_host_button_pressed() -> void:
	host_lobby()

func _on_id_prompt_text_changed(new_text: String) -> void:
	join_button.disabled = (new_text.length() == 0)

func _on_join_button_pressed() -> void:
	join_lobby(id_prompt.text.to_int())

func _on_server_visibility_item_selected(index: int) -> void:
	match index:
		0:
			public = true
			private = false
		1:
			public = false
			private = true
			

func _on_name_prompt_text_changed(new_text: String) -> void:
	host_button.disabled = (new_text.length() == 0)
