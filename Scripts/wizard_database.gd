extends Node

@export var wizards: Array[WizardTemplate] = []

func _ready() -> void:
	_load_wizards("res://Wizards")

func _load_wizards(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Invalid card path")
		return

	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if file.ends_with(".tres"):
			var wizard: WizardTemplate = load(path + "/" + file)
			wizards.push_front(wizard)
		file = dir.get_next()


func get_random_wizard() -> CardTemplate:
	return wizards.pick_random()
