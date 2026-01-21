extends Control
class_name Card


@onready var card_container: Control = $CardContainer
@onready var bg_sprite: TextureRect = $CardContainer/BGSprite
@onready var card_sprite: Sprite2D = $CardContainer/CardSprite
@onready var title: Label = $CardContainer/Title
@onready var description: RichTextLabel = $CardContainer/Description

@onready var cost_container: HBoxContainer = $CardContainer/CostContainer

@onready var left_container: VBoxContainer = $CardContainer/CostContainer/LeftContainer
@onready var fire_container: HBoxContainer = $CardContainer/CostContainer/LeftContainer/FireContainer
@onready var water_container: HBoxContainer = $CardContainer/CostContainer/LeftContainer/WaterContainer
@onready var right_container: VBoxContainer = $CardContainer/CostContainer/RightContainer
@onready var wind_container: HBoxContainer = $CardContainer/CostContainer/RightContainer/WindContainer
@onready var earth_container: HBoxContainer = $CardContainer/CostContainer/RightContainer/EarthContainer

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var deck_sprite: TextureRect = $DeckSprite
@onready var select_timer: Timer = $SelectTimer
@onready var card_type_icon: TextureRect = $CardContainer/CardTypeIcon



var nature_sprites := {
	"fire": preload("res://Assets/Nature Sprites/fire icon.png"),
	"water": preload("res://Assets/Nature Sprites/water icon.png"),
	"wind": preload("res://Assets/Nature Sprites/wind icon.png"),
	"earth": preload("res://Assets/Nature Sprites/earth icon.png")
}

var cardtype_sprites := {
	"Offensive": preload("res://Assets/Icons/crossed-swords.png"),
	"Defensive": preload("res://Assets/Icons/attached-shield.png"),
	"Utility": preload("res://Assets/Icons/backpack.png")
}

var dragging := false
var drag_offset := Vector2.ZERO
var mouse_over := false
var hand: Node2D
var base_z: int
var hovering := false

var selected: bool
var played : bool
var discarded: bool = false

# Smooth positioning
var target_position := Vector2.ZERO
var target_rotation := 0.0
@export var lerp_speed := 15.0
@export var hover_lift := 40.0

var desc_text: String

var card_stat: CardTemplate


func _ready():
	animation_player.play("card_flip")
	mouse_filter = Control.MOUSE_FILTER_STOP
	base_z = z_index
	pivot_offset = size * 0.5
	
	left_container.hide()
	right_container.hide()
	fire_container.hide()
	water_container.hide()
	wind_container.hide()
	earth_container.hide()
	
func _set_stats(stats: CardTemplate):
	self.name = stats.name
	card_stat = stats
	card_sprite.texture = stats.card_texture
	title.text = stats.name
	
	desc_text = stats.description
	
	var color = stats.nature_color_map.get(stats.Nature, Color.WHITE)
	desc_text = desc_text.replace(
		"(DMG)",
		bbcode_color(color, str(stats.dmg))
	)
	desc_text = desc_text.replace(
		"(BLOCK)",
		"[color=yellow][b]%s[/b][/color]" % stats.block
	)
	desc_text = desc_text.replace(
		"(HEAL)",
		"[color=green][b]%s[/b][/color]" % stats.heal
	)
	desc_text = desc_text.replace(
		"(DRAW)",
		"[color=web_gray][b]%s[/b][/color]" % stats.draw_amount
	)
	
	var base_color: Color = stats.nature_color_map.get(stats.Nature)
	var outline_color := base_color.lerp(Color.BLACK, 0.6)
	
	title.add_theme_color_override("font_color", base_color)
	title.add_theme_color_override("font_outline_color", outline_color)
	description.add_theme_color_override("font_outline_color", outline_color)
	
	description.text = desc_text
	_set_costs(fire_container, stats.fire_cost, "fire")
	_set_costs(water_container, stats.water_cost, "water")
	_set_costs(earth_container, stats.earth_cost, "earth")
	_set_costs(wind_container, stats.wind_cost, "wind")
	
	card_type_icon.texture = cardtype_sprites.get(stats.Card_Type)
	
func _set_costs(container: HBoxContainer, amount: int, nature: String) -> void:
	
	var texture: Texture2D = nature_sprites.get(nature)
	if texture == null:
		return
		
	for i in amount:
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		match nature:
			"fire":
				icon.custom_minimum_size = Vector2(13, 18) #0.72
				fire_container.show()
				left_container.show()
			"water":
				icon.custom_minimum_size = Vector2(10.08, 18) #0.56
				water_container.show()
				left_container.show()
			"earth":
				icon.custom_minimum_size = Vector2(26.27, 18) #1.37
				earth_container.show()
				right_container.show()
			"wind":
				icon.custom_minimum_size = Vector2(22.86, 18) #1.27
				wind_container.show()
				right_container.show()
		icon.texture = texture
		container.add_child(icon)
		
func bbcode_color(color: Color, text: String) -> String:
	return "[color=#%s][b]%s[/b][/color]" % [
		color.to_html(false),
		text
	]

func play():
	played = true
	if card_stat.discard_hand:
		for card in hand.cards.duplicate():
			if card == self:
				continue
			hand.remove_card(card)
			await hand.discard_queue_finished
	else:
		for i in range(card_stat.discard_amount):
			if hand.cards.is_empty():
				break
			hand.remove_card(hand.cards[0])
			await hand.discard_queue_finished
	
	if card_stat.draw_amount > 0:
		hand.add_card(card_stat.draw_amount)
		await hand.draw_queue_finished
		
	PlayerManager.current_attack += card_stat.dmg
	PlayerManager.current_block += card_stat.block
	
	played = false
	hand.deselect_card(self)
	hand.remove_card(self)
		
func cant_play() -> void:
	played = false
	animation_player.play("cant_play")
	
func burn_card() -> void:
	animation_player.play_backwards("card_flip")
	if material is ShaderMaterial:
		rotation_degrees = 0
		
		var mat := material as ShaderMaterial
		mat.set_shader_parameter("burnColor", card_stat.nature_color_map.get(card_stat.Nature, Color.WHITE))
		# Set starting position (center of card in UV space)
		mat.set_shader_parameter("position", random_edge_uv())
		mat.set_shader_parameter("radius", 0.0)
		
		var tween := create_tween()
		tween.tween_property(mat, "shader_parameter/radius", 1.5, 1.0)
		
		await tween.finished
		queue_free()
		
func random_edge_uv() -> Vector2:
	var t := randf() # 0–1 along the edge
	match randi() % 4:
		0: return Vector2(t, 0.0) # top
		1: return Vector2(t, 1.0) # bottom
		2: return Vector2(0.0, t) # left
		3: return Vector2(1.0, t) # right
	return Vector2.ZERO

func _process(delta: float) -> void:
	if not is_inside_tree() or discarded:
		return
		
	if PhaseManager.current_phase == PhaseManager.Phase.DEFEND and card_stat.Card_Type == "Offensive":
		modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = Color.WHITE
		
	# Check if mouse is over card
	var mouse_pos = get_global_mouse_position()
	var rect = Rect2(global_position, size)
	mouse_over = rect.has_point(mouse_pos)
	drag_offset = Vector2(size.x/2, size.y/2)
		
		
	if dragging:
		# Manual drag positioning
		global_position = global_position.lerp(mouse_pos - drag_offset, lerp_speed * delta)
		rotation_degrees = lerp(rotation_degrees, 0.0, lerp_speed * delta)
		
		if hand:
			hand.update_card_order(global_position.x)
	else:
		# Check if we should be hovering
		var can_hover = hand and not hand.is_dragging_card
		var should_hover = mouse_over and is_topmost_card() and can_hover
		
		if selected and should_hover:
			scale = scale.lerp(Vector2(1.35, 1.35), lerp_speed * delta)
			var hover_pos := target_position + Vector2(0, -hover_lift)
			global_position = global_position.lerp(hover_pos, lerp_speed * delta)
			rotation_degrees = lerp(rotation_degrees, 0.0, lerp_speed * delta)
			
		elif selected:
			var hover_pos := target_position + Vector2(0, -hover_lift)
			global_position = global_position.lerp(hover_pos, lerp_speed * delta)
			scale = scale.lerp(Vector2(1.3, 1.3), lerp_speed * delta)
			rotation_degrees = lerp(rotation_degrees, 0.0, lerp_speed * delta)
			
		elif should_hover:
			hovering = true
			global_position = global_position.lerp(target_position, lerp_speed * delta)
			scale = scale.lerp(Vector2(1.35, 1.35), lerp_speed * delta)
			rotation_degrees = lerp(rotation_degrees, target_rotation, lerp_speed * delta)
			
		else:
			hovering = false
			global_position = global_position.lerp(target_position, lerp_speed * delta)
			rotation_degrees = lerp(rotation_degrees, target_rotation, lerp_speed * delta)
			scale = scale.lerp(Vector2(1.3, 1.3), lerp_speed * delta)

func is_topmost_card() -> bool:
	if not mouse_over or not hand:
		return false
	
	var mouse_pos = get_global_mouse_position()
	var highest_z = z_index
	
	for card in hand.cards:
		if not is_instance_valid(card) or card == self:
			continue
			
		var card_rect = Rect2(card.global_position, card.size)
		if card_rect.has_point(mouse_pos) and card.z_index > highest_z:
			return false
	
	return true

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if not is_topmost_card():
				return

			mouse_over = true
			select_timer.start()

		else: # mouse released
			if dragging:
				dragging = false
				hand.stop_dragging()
				z_index = base_z

			elif not select_timer.is_stopped():
				# quick click → toggle select
				if selected:
					hand.deselect_card(self)
				else:
					hand.add_selected_card(self)
			select_timer.stop()
			
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		for i in hand.selected_cards:
			hand.deselect_card(i)
			
func _on_select_timer_timeout():
	# held long enough → drag
	if mouse_over and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dragging = true
		drag_offset = global_position - get_global_mouse_position()
		hand.start_dragging(self)

		# bring to front
		var max_z := base_z
		for card in hand.cards:
			if is_instance_valid(card):
				max_z = max(max_z, card.z_index)
		z_index = max_z + 1
