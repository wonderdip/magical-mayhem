extends Node2D

@onready var deck: Node2D = $Deck
@onready var discard: Node2D = $Discard
@onready var label: Label = $Label
@onready var label_2: Label = $Label2
@onready var label_3: Label = $Label3
@onready var label_4: Label = $Label4

@onready var natures: Node2D = $Natures
@onready var end_turn: Button = $EndTurn
@onready var play_cards: Button = $PlayCards

@export var hand_scene: PackedScene

var hand_p1: Node2D
var hand_p2: Node2D
var current_hand: Node2D

var player_has_drawn := {
	PhaseManager.PlayerTurn.PLAYER_1: false,
	PhaseManager.PlayerTurn.PLAYER_2: false
}

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	if !is_multiplayer_authority():
		return
		
	PhaseManager.phase_changed.connect(self._on_phase_changed)
	
	# Create hands manually
	if NetworkManager.total_players == NetworkManager.MAX_PLAYERS:
		_create_hands()
		
		# Start the game after a brief delay
		await get_tree().create_timer(1).timeout
		_start_game()

func _create_hands() -> void:
	# Instantiate Player 1's hand
	hand_p1 = hand_scene.instantiate()
	hand_p1.name = "HandP1"
	add_child(hand_p1)
	
	# Instantiate Player 2's hand
	hand_p2 = hand_scene.instantiate()
	hand_p2.name = "HandP2"
	hand_p2.visible = false
	NetworkManager.player_two_node.add_child(hand_p2)
	
	# Set current hand to player 1
	current_hand = hand_p1
	
func _start_game() -> void:
	# Give both players starting resources
	for player in [PhaseManager.PlayerTurn.PLAYER_1, PhaseManager.PlayerTurn.PLAYER_2]:
		PlayerManager.player_natures[player][PlayerManager.Nature.FIRE] = 3
		PlayerManager.player_natures[player][PlayerManager.Nature.WATER] = 3
		PlayerManager.player_natures[player][PlayerManager.Nature.WIND] = 3
		PlayerManager.player_natures[player][PlayerManager.Nature.EARTH] = 3
	
	# Draw initial cards for player 1
	current_hand = hand_p1
	_spawn_card(4)
	player_has_drawn[PhaseManager.PlayerTurn.PLAYER_1] = true
	natures.update_for_player()
	
	# Start in play phase
	PhaseManager.current_phase = PhaseManager.Phase.PLAY
	PhaseManager.phase_changed.emit()
	
func _switch_active_hand() -> void:
	# Switch which hand is visible and active
	if PhaseManager.current_player_turn == PhaseManager.PlayerTurn.PLAYER_1:
		current_hand = hand_p1
		hand_p1.visible = true
		hand_p2.visible = false
	else:
		current_hand = hand_p2
		hand_p1.visible = false
		hand_p2.visible = true
		
func _play_card():
	if PhaseManager.current_phase != PhaseManager.Phase.DRAW:
		current_hand.play_cards()

func _spawn_card(amount: int) -> void:
	current_hand.add_card(amount)
		
func _discard_card(dragged_card: Card):
	if current_hand.cards.size() > 0:
		current_hand.stop_dragging()
		current_hand.remove_card(dragged_card)
	
func _on_button_pressed() -> void:
	PlayerManager.add_natures(1)
	natures.update_for_player()
	
func _process(_delta: float) -> void:
	# Update phase label
	match PhaseManager.current_phase:
		PhaseManager.Phase.DRAW:
			label.text = "DRAW PHASE"
		PhaseManager.Phase.PLAY:
			label.text = "PLAY PHASE"
		PhaseManager.Phase.DEFEND:
			label.text = "DEFEND PHASE"
		PhaseManager.Phase.BATTLE:
			label.text = "BATTLE CALC"
			
	label_3.text = str(PlayerManager.current_attack)
	label_4.text = str(PlayerManager.current_block)
	
	# Update player label
	match PhaseManager.current_player_turn:
		PhaseManager.PlayerTurn.PLAYER_1:
			label_2.text = "PLAYER ONE TURN"
		PhaseManager.PlayerTurn.PLAYER_2:
			label_2.text = "PLAYER TWO TURN"
		
func _on_phase_changed() -> void:
	match PhaseManager.current_phase:
		PhaseManager.Phase.DRAW:
			# Switch to the current player's hand
			_switch_active_hand()
			
			# Draw phase: draw cards and add natures
			
			_spawn_card(PhaseManager.card_draw_amount)
			player_has_drawn[PhaseManager.current_player_turn] = true
			
			PlayerManager.add_natures(PhaseManager.nature_draw_amount)
			natures.update_for_player()
			
			# Automatically move to play phase after a short delay
			await get_tree().create_timer(0.5).timeout
			PhaseManager._change_phase()
			
		PhaseManager.Phase.PLAY:
			# Play phase: players can play cards
			pass
			
		PhaseManager.Phase.DEFEND:
			# Defend phase: handle defense/damage
			_switch_active_hand()
			
			if PhaseManager.current_player_turn == PhaseManager.PlayerTurn.PLAYER_2:
				var draw_amount = 4 if not player_has_drawn[PhaseManager.current_player_turn] else PhaseManager.card_draw_amount
				_spawn_card(draw_amount)
				
				player_has_drawn[PhaseManager.current_player_turn] = true
				natures.update_for_player()
		PhaseManager.Phase.BATTLE:
			PlayerManager.calculate_attack()
			match PhaseManager.current_player_turn:
				PhaseManager.PlayerTurn.PLAYER_2:
					PlayerManager.player_two_health -= PlayerManager.current_attack
					print(PlayerManager.player_one_health)
					print(PlayerManager.player_two_health)
				PhaseManager.PlayerTurn.PLAYER_1:
					PlayerManager.player_one_health -= PlayerManager.current_attack
					print(PlayerManager.player_one_health)
					print(PlayerManager.player_two_health)
					
			PlayerManager.current_attack = 0
			PlayerManager.current_block = 0
			PhaseManager._change_phase()
			
func _on_end_turn_pressed() -> void:
	if PhaseManager.current_phase != PhaseManager.Phase.DRAW:
		PhaseManager._change_phase()
