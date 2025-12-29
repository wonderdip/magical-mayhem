extends Node

@export var cards: Array[CardTemplate] = []

func _ready() -> void:
	_load_cards("res://Cards")

func _load_cards(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Invalid card path")
		return

	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.ends_with(".tres"):
			var card: CardTemplate = load(path + "/" + file)
			cards.push_front(card)
		file = dir.get_next()
	
func get_random_card() -> CardTemplate:
	return cards.pick_random()
