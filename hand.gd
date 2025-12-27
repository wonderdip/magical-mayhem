extends Node2D

@export var hand_center := Vector2(640, 480)  # Center of the hand arc
@export var hand_width := 960.0  # Width of the card spread
@export var hand_curve := 140.0  # How much the cards curve upward
@export var card_spacing := 100.0  # Space between cards
@export var max_rotation := 15.0  # Max rotation angle for outer cards

@onready var curve: Line2D =  $HandCurve
@onready var deck: Area2D = $"../Deck"

@export var min_hand_width := 300.0
@export var max_cards := 10

var cards: Array[Card] = []
var is_dragging_card := false

func add_card(card: Card) -> void:
	card.global_position = deck.global_position
	card.z_index = cards.size()
	deck.z_index = card.z_index + 1
	add_child(card)
	cards.append(card)
	card.hand = self
	card._set_stats(CardDatabase.get_random_card())
	update_hand()
	
func remove_card(card: Card) -> void:
	if card in cards:
		cards.erase(card)
		card.queue_free()
	update_hand()
	
func update_hand() -> void:
	var count := cards.size()
	if count == 0:
		return
	
	# 0 → few cards, 1 → full hand
	var hand_ratio : float = clamp(float(count - 1) / float(max_cards - 1), 0.0, 1.0)
	
	var effective_width : float = lerp(min_hand_width, hand_width, hand_ratio)
	
	for i in range(count):
		if cards[i].dragging:
			continue
		
		# Calculate position along arc
		var t := 0.5  # Center by default
		if count > 1:
			t = float(i) / float(count - 1)
		
		# X position spreads cards horizontally
		var x_offset := (t - 0.5) * effective_width
		
		# Y position creates arc (parabola)
		var y_offset := -hand_curve * (t - 0.5) * (t - 0.6)
		
		# Target position and rotation
		var target_pos := hand_center + Vector2(x_offset, -y_offset)
		var target_rot := (t - 0.5) * max_rotation
		
		# Smoothly animate to target (or set directly)
		cards[i].target_position = target_pos - Vector2(card_spacing/2, 0)
		cards[i].target_rotation = target_rot
		
	var points: PackedVector2Array = []
	
	# Generate points along the curve
	for i in range(33):
		var t := float(i) / float(33)
		
		# Same calculation as card positioning
		var x_offset := (t - 0.5) * effective_width
		var y_offset := -hand_curve * (t - 0.5) * (t - 0.5)
		
		var point := hand_center + Vector2(x_offset, -y_offset - 50)
		points.append(point)
		
	curve.points = points
func set_card_dragging(dragging: bool) -> void:
	is_dragging_card = dragging
