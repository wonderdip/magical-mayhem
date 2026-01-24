extends Node2D

enum LOBBY_TYPE {
	LOBBY_TYPE_PRIVATE = 0,
	LOBBY_TYPE_FRIENDS_ONLY = 1,
	LOBBY_TYPE_PUBLIC = 2,
	LOBBY_TYPE_INVISIBLE = 3
}

enum SEARCH_DISTANCE {Close, Defalut, Far, Worldwide}

var peer : SteamMultiplayerPeer
var player_scene : PackedScene = preload("res://Scenes/Player.tscn")
var is_host : bool = true
var is_joining: bool
var found_lobbies := {} # name -> id

const MAX_PLAYERS: int = 2

var lobby_visibility: LOBBY_TYPE = LOBBY_TYPE.LOBBY_TYPE_PUBLIC

@onready var host_button: Button = $UI/HostButton
@onready var refresh_button: Button = $UI/RefreshButton
@onready var id_prompt: LineEdit = $UI/IdPrompt
@onready var lobby_set_name: LineEdit = $UI/LobbySetName
@onready var server_visibility: OptionButton = $UI/ServerVisibility
@onready var ui: Control = $UI
@onready var username: Label = $UI/Username
@onready var lobbyName: Label = $UI/LobbyName
@onready var player_list: ItemList = $UI/PlayerList
@onready var lobby_list: VBoxContainer = $UI/ScrollContainer/LobbyList
@onready var lobby_search: LineEdit = $UI/LobbySearch

var player_one_node: Player
var player_two_node: Player
var peer_to_player_role := {}  # Maps peer_id -> player role (1 or 2)

func _ready() -> void:
	username.text = SteamInitializer.STEAM_NAME
	
	Steam.connect("lobby_created", _on_Lobby_Created)
	Steam.connect("lobby_match_list", _on_Lobby_Match_List)
	Steam.connect("lobby_joined", _on_Lobby_Joined)
	Steam.connect("join_requested", _on_Lobby_Join_Requested)
	check_command_line()
	
	for child in lobby_list.get_children():
		child.queue_free()
	refresh_lobbies()
	
func create_lobby():
	if SteamInitializer.LOBBY_ID == 0:
		Steam.createLobby(lobby_visibility, MAX_PLAYERS)
		is_host = true
		
func _on_Lobby_Created(connection: int, lobbyID: int): 
	if connection == 1: 
		SteamInitializer.LOBBY_ID = lobbyID 
		Steam.setLobbyData(lobbyID, "name", lobby_set_name.text)
		Steam.setLobbyData(lobbyID, "game", SteamInitializer.GAMEFILTERID) 
		var lobby_name = Steam.getLobbyData(lobbyID, "name") 
		lobbyName.text = str(lobby_name) 
		print("Lobby Created, lobby id: ", lobbyID, " Lobby Name: ", lobby_name)
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		# Host is always Player 1
		var host_id = multiplayer.get_unique_id()
		peer_to_player_role[host_id] = 1
		_add_player(host_id, 1)
		
		await get_tree().create_timer(0.1).timeout
		get_lobby_members()
		
func join_lobby(lobby_id: int):
	Steam.requestLobbyData(lobby_id)
	is_joining = true
	Steam.joinLobby(lobby_id)
	
func _on_Lobby_Joined(lobbyID: int, _permissions: int, _locked: bool, _response: int):
	if !is_joining:
		return
		
	SteamInitializer.LOBBY_ID = lobbyID
	var lobby_name = Steam.getLobbyData(lobbyID, "name")
	lobbyName.text = str(lobby_name)
	
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(Steam.getLobbyOwner(lobbyID))
	multiplayer.multiplayer_peer = peer
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	
	is_joining = false
	
func _on_connected_to_server():
	# Request player role from server
	rpc_id(1, "request_player_role")
	
	await get_tree().create_timer(0.1).timeout
	get_lobby_members()

@rpc("any_peer", "call_remote", "reliable")
func request_player_role():
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Assign Player 2 role to the client
	if sender_id not in peer_to_player_role:
		peer_to_player_role[sender_id] = 2
		
		# Tell the client their role
		rpc_id(sender_id, "assign_player_role", 2)
		
		# Add the player on the server
		_add_player(sender_id, 2)
		
		# Tell all clients about the new player
		rpc("sync_player_added", sender_id, 2)

@rpc("authority", "call_remote", "reliable")
func assign_player_role(role: int):
	var my_id = multiplayer.get_unique_id()
	peer_to_player_role[my_id] = role
	print("Assigned role: Player ", role)
	
	# Add ourselves with the correct role
	_add_player(my_id, role)

@rpc("authority", "call_remote", "reliable")
func sync_player_added(peer_id: int, role: int):
	# Skip if this is us
	if peer_id == multiplayer.get_unique_id():
		return
		
	peer_to_player_role[peer_id] = role
	if not has_node(str(peer_id)):
		_add_player(peer_id, role)
	
func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	get_lobby_members()
	
func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	_remove_player(id)
	get_lobby_members()
	
func _on_Lobby_Join_Requested(lobbyID: int, friendID: int):
	var OWNER_NAME = Steam.getFriendPersonaName(friendID)
	print("Joining " + str(OWNER_NAME) + " lobby")
	join_lobby(lobbyID)
	
func _add_player(peer_id: int, player_role: int):
	# Don't add if player already exists
	if has_node(str(peer_id)):
		print("Player node already exists for peer: ", peer_id)
		return
		
	var player = player_scene.instantiate()
	player.name = str(peer_id)
	player.lobby = self
	player.player_role = player_role  # Set the player role
	add_child(player, true)
	
	# Assign to player_one_node or player_two_node based on role
	if player_role == 1:
		player_one_node = player
		print("Player ONE set for peer: ", peer_id)
	elif player_role == 2:
		player_two_node = player
		print("Player TWO set for peer: ", peer_id)
		
		# Both players are now ready - create hands on Player 1's node
		if player_one_node != null and player_one_node.is_node_ready():
			# Only the authority for player_one creates and manages the hands
			if player_one_node.is_multiplayer_authority():
				player_one_node._create_hands()
				await get_tree().create_timer(0.1).timeout
				player_one_node._start_game()
		
func _remove_player(id: int):
	if not has_node(str(id)):
		return
	
	var player_node = get_node(str(id))
	
	# Clear references
	if player_node == player_one_node:
		player_one_node = null
	elif player_node == player_two_node:
		player_two_node = null
		
	peer_to_player_role.erase(id)
	player_node.queue_free()
	
func leave_lobby():
	if SteamInitializer.LOBBY_ID != 0:
		Steam.leaveLobby(SteamInitializer.LOBBY_ID)
		SteamInitializer.LOBBY_ID = 0
		lobbyName.text = "Lobby Name"
		player_list.clear()
		
		for MEMBERS in SteamInitializer.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(MEMBERS['steam_id'])
			
		SteamInitializer.LOBBY_MEMBERS.clear()
		peer_to_player_role.clear()
		
		# Clean up player nodes
		if player_one_node:
			player_one_node.queue_free()
			player_one_node = null
		if player_two_node:
			player_two_node.queue_free()
			player_two_node = null
		
func get_lobby_members():
	SteamInitializer.LOBBY_MEMBERS.clear()
	var MEMBERCOUNT = Steam.getNumLobbyMembers(SteamInitializer.LOBBY_ID)
	
	print("Lobby member count: ", MEMBERCOUNT)
	
	for MEMBER in range(MEMBERCOUNT):
		var MEMBER_STEAM_ID = Steam.getLobbyMemberByIndex(SteamInitializer.LOBBY_ID, MEMBER)
		if MEMBER_STEAM_ID <= 0:
			break
			
		var MEMBER_STEAM_NAME = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		add_player_list(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)
		print("Added member: ", MEMBER_STEAM_NAME, " (", MEMBER_STEAM_ID, ")")

func add_player_list(steam_id: int, steam_name: String):
	SteamInitializer.LOBBY_MEMBERS.append({"steam_id":steam_id, "steam_name": steam_name})
	player_list.clear()
	for MEMBER in SteamInitializer.LOBBY_MEMBERS:
		player_list.add_item(MEMBER.steam_name)
	
func _on_Lobby_Match_List(lobbies: Array):
	var search_text = lobby_search.text.to_lower()
	
	for LOBBY in lobbies:
		var LOBBY_NAME = Steam.getLobbyData(LOBBY, "name")
		
		if Steam.getLobbyData(LOBBY, "game") != SteamInitializer.GAMEFILTERID:
			continue
		if search_text.length() > 0 and not LOBBY_NAME.to_lower().contains(search_text):
			continue
			
		var LOBBY_MEMBERS = Steam.getNumLobbyMembers(LOBBY)
		var LOBBY_BUTTON = Button.new()
		LOBBY_BUTTON.text = "Lobby: " + LOBBY_NAME + " Members: " + str(LOBBY_MEMBERS) + "/2" + " Lobby ID: " + str(LOBBY)
		LOBBY_BUTTON.size = Vector2(100, 20)
		LOBBY_BUTTON.pressed.connect(join_lobby.bind(LOBBY))
		lobby_list.add_child(LOBBY_BUTTON)

func refresh_lobbies():
	Steam.addRequestLobbyListDistanceFilter(SEARCH_DISTANCE.Close)
	Steam.requestLobbyList()

func check_command_line():
	var ARGUMENTS = OS.get_cmdline_args()
	
	if ARGUMENTS.size() > 0:
		for arg in ARGUMENTS:
			if SteamInitializer.LOBBY_INVITE_ARG:
				join_lobby(int(arg))
				
			if arg == "+connect_lobby":
				SteamInitializer.LOBBY_INVITE_ARG = true

func _on_host_button_pressed() -> void:
	create_lobby()

func _on_id_prompt_text_submitted(new_text: String) -> void:
	if new_text.length() > 0:
		join_lobby(new_text.to_int())

func _on_name_prompt_text_changed(new_text: String) -> void:
	host_button.disabled = (new_text.length() == 0)

func _on_server_visibility_item_selected(index: int) -> void:
	match index:
		0:
			lobby_visibility = LOBBY_TYPE.LOBBY_TYPE_PUBLIC
		1:
			lobby_visibility = LOBBY_TYPE.LOBBY_TYPE_FRIENDS_ONLY

func _on_leave_button_pressed() -> void:
	leave_lobby()

func _on_close_button_pressed() -> void:
	for child in lobby_list.get_children():
		child.queue_free()

func _on_lobby_search_text_changed(_new_text: String) -> void:
	for child in lobby_list.get_children():
		child.queue_free()
	
	refresh_lobbies()

func _on_refresh_button_pressed() -> void:
	for child in lobby_list.get_children():
		child.queue_free()
		
	refresh_lobbies()
