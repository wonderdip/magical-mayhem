extends Node2D

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

var steam_init: bool = false

@onready var host_button: Button = $UI/HostButton
@onready var join_button: Button = $UI/JoinButton
@onready var id_prompt: LineEdit = $UI/IdPrompt
@onready var name_prompt: LineEdit = $UI/NamePrompt
@onready var server_visibility: OptionButton = $UI/ServerVisibility
@onready var ui: Control = $UI
