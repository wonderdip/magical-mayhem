extends Resource
class_name CardTemplate

@export var name: String
@export var special: bool = false
@export var dmg: int = 0
@export var block: int = 0
@export var heal: int = 0
@export var draw_amount: int = 0
@export var discard_amount: int = 0
@export var discard_hand: bool = false
@export var fire_cost: int = 0
@export var water_cost: int = 0
@export var wind_cost: int = 0
@export var earth_cost: int = 0
@export var card_texture: Texture2D
@export_enum("Fire", "Water", "Wind", "Earth") var Nature: String
@export_enum("Offensive", "Defensive", "Utility") var Card_Type: String
@export_multiline var description: String

@export var fire_colour: Color = Color(0.906, 0.369, 0.0)
@export var water_colour: Color = Color(0.188, 0.545, 0.871)
@export var wind_colour: Color = Color(0.9, 0.9, 0.9)
@export var earth_colour: Color = Color(0.251, 0.169, 0.035)

var nature_color_map := { 
	"Fire": fire_colour, 
	"Water": water_colour, 
	"Wind": wind_colour, 
	"Earth": earth_colour, 
	}
