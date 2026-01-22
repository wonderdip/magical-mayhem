extends Node

var lobby_id: int = 0
var peer : SteamMultiplayerPeer
var player_scene : PackedScene = preload("res://Scenes/Player.tscn")
var is_host : bool = true
var is_joining: bool
var private: bool = false
var public: bool = true
var found_lobbies := {} # name -> id
var total_players: int = 0
const MAX_PLAYERS: int = 2

var player_one_node: Node2D
var player_two_node: Node2D
@onready var lobby: Node2D = $"."

func _ready() -> void:
	
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
		
func _on_lobby_match_list(lobbies: Array):
	if lobbies.is_empty():
		print("No lobby with that name")
		return

	var lobby_id = lobbies[0]
	join_lobby(lobby_id, Steam.getLobbyData(lobby_id, "name"))

func host_lobby():
	if private:
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_FRIENDS_ONLY, MAX_PLAYERS)
	elif public:
		Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, MAX_PLAYERS)
		
	is_host = true
	
	@warning_ignore("shadowed_variable")
func _on_lobby_created(result: int, lobby_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lobby_id
		Steam.setLobbyData(lobby_id, "name", lobby.name_prompt.text)
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		
		multiplayer.peer_connected.connect(_add_player)
		multiplayer.peer_disconnected.connect(_remove_player)
		total_players += 1
		_add_player()
		
		print("Lobby Created, lobby id: ", lobby_id, "Lobby Private: ", private, "Lobby Public: ", public)
		
		lobby.ui.hide()
		
	@warning_ignore("shadowed_variable")
func join_lobby(lobby_id: int, lobby_name: String):
	if lobby_name:
		Steam.requestLobbyData(lobby_id)
	is_joining = true
	Steam.joinLobby(lobby_id)

func join_lobby_by_name(name: String):
	if not found_lobbies.has(name):
		print("No lobby with that name")
		return

	var lobby_id = found_lobbies[name]
	join_lobby(lobby_id, name)

	@warning_ignore("shadowed_variable")
func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int):
	
	if !is_joining:
		return
		
	self.lobby_id = lobby_id
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobby_id))
	multiplayer.multiplayer_peer = peer
	total_players += 1
	lobby.ui.hide()
	is_joining = false
	
func _add_player(id: int = 1):
	var player = player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)
	
	match total_players:
		1:
			player_one_node = player
		2:
			player_two_node = player
	
	
func _remove_player(id: int):
	if not self.has_node(str(id)):
		return
	
	self.get_node(str(id)).queue_free()

func _on_host_button_pressed() -> void:
	host_lobby()

func _on_id_prompt_text_changed(new_text: String) -> void:
	lobby.join_button.disabled = (new_text.length() == 0)

func _on_join_button_pressed() -> void:
	Steam.addRequestLobbyListStringFilter(
		"name",
		lobby.id_prompt.text,
		Steam.LobbyComparison.LOBBY_COMPARISON_EQUAL
	)
	Steam.requestLobbyList()

func _on_server_visibility_item_selected(index: int) -> void:
	match index:
		0:
			public = true
			private = false
		1:
			public = false
			private = true
			

func _on_name_prompt_text_changed(new_text: String) -> void:
	lobby.host_button.disabled = (new_text.length() == 0)
