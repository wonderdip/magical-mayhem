extends Node2D

@onready var fire_label: Label = $NatureContainer/FireContainer/FireLabel
@onready var water_label: Label = $NatureContainer/WaterContainer/WaterLabel
@onready var wind_label: Label = $NatureContainer/WindContainer/WindLabel
@onready var earth_label: Label = $NatureContainer/EarthContainer/EarthLabel

func change_labels():
	fire_label.text = str(Natures.fire_natures)
	water_label.text = str(Natures.water_natures)
	wind_label.text = str(Natures.wind_natures)
	earth_label.text = str(Natures.earth_natures)
