extends Spatial

onready var monster = $GridMap/Monster
onready var player = $GridMap/Player



func _ready():
	monster.set_target(player)

