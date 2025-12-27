extends Node2D


@onready var hand: Node2D = $Hand
@onready var deck: Node2D = $Deck

func _ready() -> void:
	deck.connect("draw_card", _spawn_card)
	
func _on_button_pressed() -> void:
	_spawn_card()

func _spawn_card():
	var new_card = preload("res://card.tscn")
	var card_instance = new_card.instantiate()
	hand.add_card(card_instance)

func _on_button_2_pressed() -> void:
	if hand.cards.size() > 0:
		hand.remove_card(hand.cards[0])
	
