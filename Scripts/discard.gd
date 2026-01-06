extends Node2D

signal discard_card(card)

var hovering: bool
var hand: Node2D  # This will be set by main.gd
@onready var discard_sprite: TextureRect = $DiscardSprite

func _ready() -> void:
	# hand reference will be set by main.gd when it switches hands
	pass

func _on_discard_sprite_mouse_entered() -> void:
	if hand and hand.is_dragging_card:
		hovering = true

func _process(delta: float) -> void:
	if not hand:
		return
		
	if hovering and hand.dragged_card != null:
		hand.dragged_card.modulate = hand.dragged_card.modulate.lerp(Color(0.5, 0.5, 0.5, 1.0), 10 * delta)
		
	elif not hovering and hand.is_dragging_card and hand.dragged_card != null:
		hand.dragged_card.modulate = hand.dragged_card.modulate.lerp(Color.WHITE, 10 * delta)
		
func _input(event: InputEvent) -> void:
	if not hand:
		return
		
	if hovering \
	and event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and not event.pressed:
		
		discard_card.emit(hand.dragged_card)
		hovering = false

func _on_discard_sprite_mouse_exited() -> void:
	if hand and hand.is_dragging_card:
		hovering = false
