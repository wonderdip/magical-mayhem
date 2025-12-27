extends Control
class_name Card

@onready var card_sprite: Sprite2D = $Container/CardSprite
@onready var bg_sprite: TextureRect = $Container/BGSprite
@onready var title: Label = $Container/Title
@onready var description: RichTextLabel = $Container/Description
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var dragging := false
var drag_offset := Vector2.ZERO
var mouse_over := false
var hand: Node2D  # Reference to hand
var base_z: int
var hovering := false

# Smooth positioning
var target_position := Vector2.ZERO
var target_rotation := 0.0
@export var lerp_speed := 15.0
@export var hover_lift := 20.0

func _ready():
	animation_player.play("card_flip")
	mouse_filter = Control.MOUSE_FILTER_STOP
	base_z = z_index
	pivot_offset = size * 0.5


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

func bbcode_color(color: Color, text: String) -> String:
	return "[color=#%s][b]%s[/b][/color]" % [
		color.to_html(false),
		text
	]

func _process(delta: float) -> void:
	if not is_inside_tree():
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
	else:
		# Check if we should be hovering
		var can_hover = hand and not hand.is_dragging_card
		var should_hover = mouse_over and is_topmost_card() and can_hover
		
		if should_hover:
			# Hovering state - lift card up and scale
			hovering = true
			var hover_pos := target_position + Vector2(0, -hover_lift)
			global_position = global_position.lerp(hover_pos, lerp_speed * delta)
			scale = scale.lerp(Vector2(1.1, 1.1), lerp_speed * delta)
			
		else:
			# Normal state - return to target
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
		if card != self:
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
			hand.set_card_dragging(true)
			
			# Bring to front
			var max_z = base_z
			for card in hand.cards:
				max_z = max(max_z, card.z_index)
			z_index = max_z + 1
			
			get_viewport().set_input_as_handled()
			
		elif not event.pressed and dragging:
			# Stop dragging
			dragging = false
			z_index = base_z
			hand.set_card_dragging(false)
			hand.update_hand()
			get_viewport().set_input_as_handled()
