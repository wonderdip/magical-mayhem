extends Node

enum Nature { FIRE, WATER, WIND, EARTH }

var player_natures := {
	PhaseManager.PlayerTurn.PLAYER_1: {
		Nature.FIRE: 0,
		Nature.WATER: 0,
		Nature.WIND: 0,
		Nature.EARTH: 0,
	},
	PhaseManager.PlayerTurn.PLAYER_2: {
		Nature.FIRE: 0,
		Nature.WATER: 0,
		Nature.WIND: 0,
		Nature.EARTH: 0,
	}
}

var player_one_health :  int = 25
var player_two_health : int = 25

var current_attack : int = 0
var current_block : int = 0

func _ready() -> void:
	randomize()

func add_natures(amount: int) -> void:
	for i in range(amount):
		var roll := randi() % 4
		player_natures[PhaseManager.current_player_turn][roll] += 1

func calculate_attack():
	current_attack -= current_block
