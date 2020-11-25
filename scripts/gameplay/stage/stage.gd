extends Node

var player_scn = preload("res://scripts/gameplay/player/player.tscn")

onready var arena = $Arena
onready var camera = $Arena/Camera
onready var spawn_points = $Arena/Level/SpawnPoints

onready var countdown_label = $UI/Countdown
onready var tween = $UI/Tween

onready var countdown_timer = $CountdownTimer

# ...to store all player instances, might come in handy.
var player_instances : Array

var my_player : RigidBody2D

var counting_down : bool = true


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
			
			spawn_counter += 1
			
			player_instances.append(p_ins)
		
		my_player = arena.get_node(Network.players[get_tree().get_network_unique_id()]["player_info"]["name"])
		
		_do_countdown()
	# If not, then this scene must have been run on the editor
	# because in normal occasions, it is impossible to get here
	# without network initialized.
	else:
		var p_name : String = Global.player_info["name"]
			
		# Instance player
		var p_ins = player_scn.instance()
		
		p_ins.test_mode = true
		p_ins.can_move = true
		
		arena.add_child(p_ins)
		
		# Set player name on node name and label.
		p_ins.name = p_name
		p_ins.player_name.text = p_name
		
		# Set starting pos
		p_ins.position = spawn_points.get_node("1").position
		
		my_player = p_ins
		
		_start_game()


func _process(delta: float) -> void:
	if Network.enet: if get_tree().is_network_server():
		if counting_down:
			rpc("_update_countdown", str(ceil(countdown_timer.time_left)))
			if countdown_timer.time_left == 0:
				rpc("_start_game")
				counting_down = false


func _physics_process(delta: float) -> void:
	camera.position = lerp(camera.position, my_player.position, 0.1)


func _do_countdown() -> void:
	countdown_timer.start()


remotesync func _update_countdown(text : String) -> void:
	countdown_label.text = text


remotesync func _start_game() -> void:
	for ins in player_instances:
		ins.can_move = true
	
	countdown_label.text = "Go!"
	
	tween.interpolate_property(countdown_label, "rect_scale", Vector2(1, 1), Vector2(1.5, 1.5), 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.75)
	tween.interpolate_property(countdown_label, "modulate:a", 1, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.75)
	tween.interpolate_property(countdown_label, "visible", 1, 0, 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN, 0.75)
	tween.start()
