extends Node2D


@onready var hand: Node2D = $Hand
@onready var deck: Node2D = $Deck
@onready var discard: Node2D = $Discard
@onready var label: Label = $Label

func _ready() -> void:
	deck.connect("draw_card", _spawn_card)
	discard.connect("discard_card", _discard_card)
	PhaseManager.phase_changed.connect(self._on_phase_changed)
	PhaseManager._change_phase()
func _play_card():
	hand.play_cards()
	
func _spawn_card(amount: int):
	for i in range(amount):
		hand.add_card()

func _discard_card(dragged_card: Card):
	if hand.cards.size() > 0:
		hand.stop_dragging()
		hand.remove_card(dragged_card)
	
func _on_button_pressed() -> void:
	_play_card()
func _process(_delta: float) -> void:
	match PhaseManager.current_phase:
		0:
			label.text = "DRAW PHASE"
		1:
			label.text = "PLAY PHASE"
		2:
			label.text = "DEFEND PHASE"
			
func _on_phase_changed() -> void:
	if PhaseManager.current_phase == PhaseManager.Phase.DRAW:
		_spawn_card(PhaseManager.card_draw_amount)
		PhaseManager._change_phase()

func _on_advance_phase_pressed() -> void:
	PhaseManager._change_phase()
