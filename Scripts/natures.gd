extends Node

var fire_natures := 0
var water_natures := 0
var wind_natures := 0
var earth_natures := 0

func _ready() -> void:
	randomize()


func add_natures(amount: int) -> void:
	for i in range(amount):
		var roll := randi() % 4
		match roll:
			0:
				fire_natures += 1
			1:
				water_natures += 1
			2:
				wind_natures += 1
			3:
				earth_natures += 1
