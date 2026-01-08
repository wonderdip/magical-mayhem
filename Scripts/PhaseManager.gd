extends Node

signal phase_changed

@export var card_draw_amount: int = 2
@export var nature_draw_amount: int = 3

enum PlayerTurn { PLAYER_1, PLAYER_2 }
enum Phase { DRAW, PLAY, DEFEND, BATTLE }

@export var current_player_turn: PlayerTurn = PlayerTurn.PLAYER_1
@export var current_phase: Phase = Phase.BATTLE

func _ready() -> void:
	current_player_turn = PlayerTurn.PLAYER_1
	
func _change_phase() -> void:
	current_phase = (current_phase + 1) % Phase.size() as Phase
	if current_phase == Phase.DEFEND:
		current_player_turn = (current_player_turn + 1) % PlayerTurn.size() as PlayerTurn
	phase_changed.emit()
		
func _change_player_turn() -> void:
	current_player_turn = (current_player_turn + 1) % PlayerTurn.size() as PlayerTurn
	
