extends Node2D

signal discard_card(card)

var hovering: bool
@onready var hand: Node2D = $"../Hand"
@onready var discard_sprite: TextureRect = $DiscardSprite

func _on_discard_sprite_mouse_entered() -> void:
	if hand.is_dragging_card == true:
		hovering = true
		
		print(hovering)

func _process(delta: float) -> void:
	if hovering and !hand.dragged_card == null:
		hand.dragged_card.modulate = modulate.lerp(Color(-5.0, -5.0, -5.0, 1.0), 10 * delta)
		
	elif !hovering and hand.is_dragging_card and !hand.dragged_card == null:
		hand.dragged_card.modulate = modulate.lerp(Color.WHITE, 10 * delta)
		
func _input(event: InputEvent) -> void:
	if hovering \
	and event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.pressed:
		
		discard_card.emit(hand.dragged_card)
		hovering = false


func _on_discard_sprite_mouse_exited() -> void:
	if hand.is_dragging_card:
		hovering = false
