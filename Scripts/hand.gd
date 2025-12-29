extends Node2D

@export var hand_center := Vector2(640, 480)
@export var hand_width := 640.0
@export var hand_curve := 140.0
@export var card_spacing := 100.0
@export var max_rotation := 15.0

@onready var curve: Line2D =  $HandCurve
@onready var deck: Node2D = $"../Deck"
@onready var discard: Node2D = $"../Discard"

@export var min_hand_width := 160.0
@export var max_cards := 10
@export var max_handsize: int = 20

var cards: Array[Card] = []
var is_dragging_card := false
var dragged_card: Card = null
var dragged_card_original_index: int = -1

var selected_cards: Array[Card] = []

func add_card() -> void:
	var new_card = preload("res://Scenes/card.tscn")
	var card = new_card.instantiate()
	
	if cards.size() <= max_handsize:
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
		card.animation_player.play("discard")
		card.global_position = discard.global_position
		await card.animation_player.animation_finished
		card.queue_free()
	update_hand()

func add_selected_card(card: Card) -> void:
	if card in selected_cards:
		return
	selected_cards.append(card)
	card.selected = true
	update_hand()

func remove_selected_card(card: Card) -> void:
	if card not in selected_cards:
		return
	selected_cards.erase(card)
	card.selected = false
	update_hand()

func play_cards():
	for card in selected_cards:
		card.play()
		
func update_hand() -> void:
	var count := cards.size()
	if count == 0:
		return
	
	var hand_ratio : float = clamp(float(count - 1) / float(max_cards - 1), 0.0, 1.0)
	var effective_width : float = lerp(min_hand_width, hand_width, hand_ratio)
	
	for i in range(count):
		var card = cards[i]
		if not is_instance_valid(card):
			continue
			
		if card.dragging:
			continue
		
		var t := 0.5
		if count > 1:
			t = float(i) / float(count - 1)
		
		var x_offset := (t - 0.5) * effective_width
		var y_offset := -hand_curve * (t - 0.5) * (t - 0.6)
		
		var target_pos := hand_center + Vector2(x_offset, -y_offset)
		var target_rot := (t - 0.5) * max_rotation
		
		card.target_position = target_pos - Vector2(card_spacing/2, 0)
		card.target_rotation = target_rot
		card.base_z = count + i
		card.z_index = card.base_z
		
	var points: PackedVector2Array = []
	for i in range(33):
		var t := float(i) / float(33)
		var x_offset := (t - 0.5) * effective_width
		var y_offset := -hand_curve * (t - 0.5) * (t - 0.5)
		var point := hand_center + Vector2(x_offset, -y_offset - 50)
		points.append(point)
	curve.points = points

func start_dragging(card: Card) -> void:
	is_dragging_card = true
	dragged_card = card
	dragged_card_original_index = cards.find(card)

func update_card_order(global_x: float) -> void:
	if dragged_card == null or dragged_card_original_index == -1:
		return
	
	var new_index := get_insert_index(global_x)
	new_index = clamp(new_index, 0, cards.size() - 1)
	
	if new_index != dragged_card_original_index:
		# Remove from old position
		cards.remove_at(dragged_card_original_index)
		# Insert at new position
		cards.insert(new_index, dragged_card)
		dragged_card_original_index = new_index
		# Refresh layout
		update_hand()

func stop_dragging() -> void:
	is_dragging_card = false
	dragged_card = null
	dragged_card_original_index = -1
	update_hand()

func get_insert_index(global_x: float) -> int:
	var count := cards.size()
	if count <= 1:
		return 0
	
	var effective_width := effective_hand_width()
	var hand_left := hand_center.x - effective_width * 0.65
	var hand_right := hand_center.x + effective_width * 0.4
	
	var t = clamp(
		(global_x - hand_left) / (hand_right - hand_left),
		0.0,
		1.0
	)
	
	return int(round(t * (count - 1)))
	
func effective_hand_width() -> float:
	var count = cards.size()
	if count <= 1:
		return min_hand_width
	var hand_ratio : float = clamp(float(count - 1) / float(max_cards - 1), 0.0, 1.0)
	return lerp(min_hand_width, hand_width, hand_ratio)
