extends Node2D

@onready var fire_label: Label = $NatureContainer/FireContainer/FireLabel
@onready var water_label: Label = $NatureContainer/WaterContainer/WaterLabel
@onready var wind_label: Label = $NatureContainer/WindContainer/WindLabel
@onready var earth_label: Label = $NatureContainer/EarthContainer/EarthLabel

func update_for_player() -> void:
	var natures = PlayerManager.player_natures[PhaseManager.current_player_turn]

	fire_label.text = str(natures[PlayerManager.Nature.FIRE])
	water_label.text = str(natures[PlayerManager.Nature.WATER])
	wind_label.text = str(natures[PlayerManager.Nature.WIND])
	earth_label.text = str(natures[PlayerManager.Nature.EARTH])
