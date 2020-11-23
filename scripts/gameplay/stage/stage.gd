extends Node

var player_scn = preload("res://scripts/gameplay/player/player.tscn")

var my_player : RigidBody2D

onready var arena = $Arena
onready var camera = $Arena/Camera
onready var spawn_points = $Arena/Level/SpawnPoints


func _ready() -> void:
	# Check if network initialized.
	if Network.enet:
		var spawn_counter : int = 1
		
		for player in Network.players:
			var p_name : String = Network.players[player]["player_info"]["name"]
			
			# Instance player
			var p_ins = player_scn.instance()
			
			p_ins.set_network_master(player)
			
			arena.add_child(p_ins)
			
			# Set player name on node name and label.
			p_ins.name = p_name
			p_ins.player_name.text = p_name
			
			# Set starting pos
			p_ins.position = spawn_points.get_node(str(spawn_counter)).position
		
		my_player = arena.get_node(Network.players[get_tree().get_network_unique_id()]["player_info"]["name"])
	# If not, then this scene must have been run on the editor
	# because in normal occasions, it is impossible to get here
	# without network initialized.
	else:
		var p_name : String = Global.player_info["name"]
			
		# Instance player
		var p_ins = player_scn.instance()
		
		p_ins.test_mode = true
		
		arena.add_child(p_ins)
		
		# Set player name on node name and label.
		p_ins.name = p_name
		p_ins.player_name.text = p_name
		
		# Set starting pos
		p_ins.position = spawn_points.get_node("1").position
		
		my_player = p_ins


func _physics_process(delta: float) -> void:
	camera.position = lerp(camera.position, my_player.position, 0.1)
