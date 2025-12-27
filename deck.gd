extends Area2D

@onready var deck_sprite: TextureRect = $DeckSprite

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	deck_sprite.pivot_offset = deck_sprite.size * 0.5
	
	var tween := get_tree().create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(deck_sprite, "rotation_degrees", 8, 5.0)
	tween.tween_property(deck_sprite, "rotation_degrees", -8, 5.0)
