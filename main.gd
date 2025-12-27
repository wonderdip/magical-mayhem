extends Node2D


@onready var hand: Node2D = $Hand

func _on_button_pressed() -> void:
	var new_card = preload("res://card.tscn")
	var card_instance = new_card.instantiate()
	hand.add_card(card_instance)

func _on_button_2_pressed() -> void:
	if hand.cards.size() > 0:
		hand.remove_card(hand.cards[0])
	
