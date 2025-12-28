extends Node2D


@onready var hand: Node2D = $Hand
@onready var deck: Node2D = $Deck
@onready var discard: Node2D = $Discard

func _ready() -> void:
	deck.connect("draw_card", _spawn_card)
	discard.connect("discard_card", _discard_card)
	
func _on_button_pressed() -> void:
	_spawn_card()

func _spawn_card():
	var new_card = preload("res://card.tscn")
	var card_instance = new_card.instantiate()
	hand.add_card(card_instance)

func _discard_card(dragged_card: Card):
	if hand.cards.size() > 0:
		hand.stop_dragging()
		hand.remove_card(dragged_card)
	
