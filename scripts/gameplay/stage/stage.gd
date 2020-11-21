extends Node

var player_scn = preload("res://scripts/gameplay/player/player.tscn")

var my_player : RigidBody2D

onready var arena = $Arena
onready var camera = $Arena/Camera
onready var spawn_points = $Arena/Level/SpawnPoints


func _ready() -> void:
	var player_ins = player_scn.instance()
	arena.add_child(player_ins)
	player_ins.global_position = spawn_points.get_node("1").global_position
	my_player = player_ins


func _physics_process(delta: float) -> void:
	camera.position = lerp(camera.position, my_player.position, 0.1)
