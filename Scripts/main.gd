extends Node2D

@onready var hand: Node2D = $Hand
@onready var deck: Node2D = $Deck
@onready var discard: Node2D = $Discard
@onready var label: Label = $Label
@onready var label_2: Label = $Label2
@onready var natures: Node2D = $Natures
@onready var end_turn: Button = $EndTurn
@onready var play_cards: Button = $PlayCards

var is_first_draw: bool = true

func _ready() -> void:
	deck.connect("draw_card", _spawn_card)
	discard.connect("discard_card", _discard_card)
	
	PhaseManager.phase_changed.connect(self._on_phase_changed)
	
	# Wait one frame to ensure all @onready variables are initialized
	await get_tree().create_timer(1).timeout
	PhaseManager.call_deferred("_change_phase")
	
func _play_card(): # on playcard button pressed
	if PhaseManager.current_phase == PhaseManager.Phase.PLAY:
		hand.play_cards()
	
var is_drawing := false
var draw_queue: int = 0

func _spawn_card(amount: int) -> void:
	hand.add_card(amount)
		
func _discard_card(dragged_card: Card):
	if hand.cards.size() > 0:
		hand.stop_dragging()
		hand.remove_card(dragged_card)
	
func _on_button_pressed() -> void:
	PlayerManager.add_natures(1)
	natures.update_for_labels()
	
func _process(_delta: float) -> void:
	match PhaseManager.current_phase:
		0:
			label.text = "DRAW PHASE"
		1:
			label.text = "PLAY PHASE"
		2:
			label.text = "DEFEND PHASE"
			
	match PhaseManager.current_player_turn:
		0:
			label_2.text = "PLAYER ONE TURN"
			end_turn.disabled = false
			play_cards.disabled = false
		1:
			label_2.text = "PLAYER TWO TURN"
			end_turn.disabled = true
			play_cards.disabled = true
		
		
func _on_phase_changed() -> void:
	if PhaseManager.current_phase == PhaseManager.Phase.DRAW:
		if is_first_draw:
			_spawn_card(2)
			PlayerManager.add_natures(6)
			is_first_draw = false
			
		_spawn_card(PhaseManager.card_draw_amount)
		PlayerManager.add_natures(PhaseManager.nature_draw_amount)
		natures.update_for_player()
		PhaseManager._change_phase()

func _on_end_turn_pressed() -> void:
	PhaseManager._change_phase()
