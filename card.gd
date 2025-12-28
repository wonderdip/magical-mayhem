extends Control
class_name Card

@onready var card_sprite: Sprite2D = $Container/CardSprite
@onready var bg_sprite: TextureRect = $Container/BGSprite
@onready var title: Label = $Container/Title
@onready var description: RichTextLabel = $Container/Description
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var fire_cost: HBoxContainer = $Container/HBoxContainer/LeftCost/FireCost
@onready var water_cost: HBoxContainer = $Container/HBoxContainer/LeftCost/WaterCost
@onready var wind_cost: HBoxContainer = $Container/HBoxContainer/RightCost/WindCost
@onready var earth_cost: HBoxContainer = $Container/HBoxContainer/RightCost/EarthCost

@onready var left_cost: VBoxContainer = $Container/HBoxContainer/LeftCost
@onready var right_cost: VBoxContainer = $Container/HBoxContainer/RightCost

var nature_sprites := {
	"fire": preload("res://Assets/Nature Sprites/fire icon.png"),
	"water": preload("res://Assets/Nature Sprites/water icon.png"),
	"wind": preload("res://Assets/Nature Sprites/wind icon.png"),
	"earth": preload("res://Assets/Nature Sprites/earth icon.png")
}


var dragging := false
var drag_offset := Vector2.ZERO
var mouse_over := false
var hand: Node2D
var base_z: int
var hovering := false

# Smooth positioning
var target_position := Vector2.ZERO
var target_rotation := 0.0
@export var lerp_speed := 15.0
@export var hover_lift := 40.0

func _ready():
	animation_player.play("card_flip")
	mouse_filter = Control.MOUSE_FILTER_STOP
	base_z = z_index
	pivot_offset = size * 0.5
	
	left_cost.hide()
	right_cost.hide()
	fire_cost.hide()
	water_cost.hide()
	wind_cost.hide()
	earth_cost.hide()
	
func _set_stats(stats: CardTemplate):
	self.name = stats.name
	card_sprite.texture = stats.card_texture
	title.text = stats.name
	
	var desc_text := stats.description
	
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
	description.text = desc_text
	
	_set_costs(fire_cost, stats.fire_cost, "fire")
	_set_costs(water_cost, stats.water_cost, "water")
	_set_costs(earth_cost, stats.earth_cost, "earth")
	_set_costs(wind_cost, stats.wind_cost, "wind")
func _set_costs(container: HBoxContainer, amount: int, nature: String) -> void:
	var texture: Texture2D = nature_sprites.get(nature)
	if texture == null:
		return

	for i in amount:
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		match nature:
			"fire":
				icon.custom_minimum_size = Vector2(10.18, 14)
				fire_cost.show()
				left_cost.show()
			"water":
				icon.custom_minimum_size = Vector2(7.56, 14)
				water_cost.show()
				left_cost.show()
			"earth":
				icon.custom_minimum_size = Vector2(19.18, 14)
				earth_cost.show()
				right_cost.show()
			"wind":
				icon.custom_minimum_size = Vector2(17.78, 14)
				wind_cost.show()
				right_cost.show()
		icon.texture = texture
		container.add_child(icon)
		
		
func bbcode_color(color: Color, text: String) -> String:
	return "[color=#%s][b]%s[/b][/color]" % [
		color.to_html(false),
		text
	]

func _process(delta: float) -> void:
	if not is_inside_tree() or animation_player.current_animation == "discard":
		return
	
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
		
		if should_hover:
			# Hovering state
			hovering = true
			var hover_pos := target_position + Vector2(0, -hover_lift)
			global_position = global_position.lerp(hover_pos, lerp_speed * delta)
			scale = scale.lerp(Vector2(1.1, 1.1), lerp_speed * delta)
		else:
			# Normal state
			hovering = false
			global_position = global_position.lerp(target_position, lerp_speed * delta)
			rotation_degrees = lerp(rotation_degrees, target_rotation, lerp_speed * delta)
			scale = scale.lerp(Vector2(1, 1), lerp_speed * delta)

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

func _input(event: InputEvent) -> void:
	if not is_inside_tree() or not hand:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and mouse_over and not dragging:
			if not is_topmost_card():
				return
			
			# Start dragging
			dragging = true
			hovering = false
			drag_offset = global_position - get_global_mouse_position()
			hand.start_dragging(self)
			
			# Bring to front
			var max_z = base_z
			for card in hand.cards:
				if is_instance_valid(card):
					max_z = max(max_z, card.z_index)
			z_index = max_z + 1
			
			get_viewport().set_input_as_handled()
			
		elif not event.pressed and dragging:
			dragging = false
			hand.stop_dragging()
			z_index = base_z
