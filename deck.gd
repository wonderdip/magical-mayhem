extends Node2D

signal draw_card

@onready var deck_sprite: TextureRect = $DeckSprite
@onready var poptimer: Timer = $Poptimer

var drew_card: bool
var hover: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	drew_card = false
	deck_sprite.pivot_offset = deck_sprite.size * 0.5
	deck_sprite.rotation_degrees = -5
	
	var tween := get_tree().create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(deck_sprite, "rotation_degrees", 5, 5.0)
	tween.tween_property(deck_sprite, "rotation_degrees", -5, 5.0)


func _process(delta: float) -> void:
	
	if hover and !drew_card:
		deck_sprite.scale = deck_sprite.scale.lerp(Vector2(1.1, 1.1), 10 * delta)
		deck_sprite.self_modulate = deck_sprite.self_modulate.lerp(Color(1.3, 1.3, 1.3), 10 * delta)
	elif drew_card:
		deck_sprite.scale = deck_sprite.scale.lerp(Vector2.ONE, 10 * delta)
		deck_sprite.self_modulate = deck_sprite.self_modulate.lerp(Color(1.3, 1.3, 1.3), 10 * delta)
	else:
		deck_sprite.self_modulate = deck_sprite.self_modulate.lerp(Color.WHITE, 10 * delta)
		deck_sprite.scale = deck_sprite.scale.lerp(Vector2.ONE, 10 * delta)
		
	if poptimer.is_stopped():
		drew_card = false

func _on_deck_sprite_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			draw_card.emit()
			drew_card = true
			poptimer.start()


func _on_deck_sprite_mouse_entered() -> void:
	hover = true

func _on_deck_sprite_mouse_exited() -> void:
	hover = false
