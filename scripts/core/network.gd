extends Node

signal player_list_changed
signal player_ready_changed

signal game_initializing
signal game_initializing_aborted
signal game_end

# Essential server information
const PORT = 23719
const MAX_PEERS = 4

# Contains ENet created when joining or creating a server.
var enet : NetworkedMultiplayerENet

# Contains registered players.
var players : Dictionary = {}

# Track current state with enums.
# Idle: in lobby, Init: when init, Game: when in game.
enum {
	STATE_IDLE,
	STATE_INITIALIZE,
	STATE_GAME
}
var state : int = STATE_IDLE

var init_timer : Timer


func _ready() -> void:
	# Called in both client and server
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	# Client specific
	get_tree().connect("connected_to_server", self, "_on_connected")
	get_tree().connect("server_disconnected", self, "_on_disconnected")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	
	init_timer = Timer.new()
	init_timer.one_shot = true
	init_timer.wait_time = 2
	add_child(init_timer)
	init_timer.connect("timeout", self, "_initialize_game")

## SceneTree callbacks

# Client & Server

func _on_peer_connected(id : int) -> void:
	print("Peer ID " + str(id) + " connected.")


func _on_peer_disconnected(id : int) -> void:
	print("Peer ID " + str(id) + " disconnected.")
	call_deferred("_unregister_player", id)
	
	if get_tree().is_network_server():
		# Abort when in the middle of initialization
		if state == STATE_INITIALIZE:
			rpc("_abort_initialize_game")
		# When in game, execute end game function everywhere
		elif state == STATE_GAME:
			rpc("_end_game")

# Client only

func _on_connected() -> void:
	print("Connected to server.")
	# Request server to register itself, passing along player info.
	rpc_id(1, "_register_player", get_tree().get_network_unique_id(), Global.player_info, false)


func _on_disconnected() -> void:
	print("Disconnected from server.")
	
	# When in game, end it immediately.
	if state == STATE_GAME:
		_end_game()


func _on_connection_failed() -> void:
	pass

## Server functions

func create_server() -> void:
	enet = NetworkedMultiplayerENet.new()
	enet.create_server(PORT, MAX_PEERS)
	get_tree().network_peer = enet
	
	_register_player(1, Global.player_info, false)
	
	print("Server created.")


func join_server(ip : String) -> void:
	enet = NetworkedMultiplayerENet.new()
	enet.create_client(ip, PORT)
	get_tree().network_peer = enet
	
	print("Connecting...")


func close_network() -> void:
	var verb : String = "Network"
	
	if enet or get_tree().network_peer:
		if get_tree().is_network_server(): verb = "Server"
		else: "Client"
		
		enet.close_connection()
		enet = null
	
	players.clear()
	
	print(verb + " closed.")

## Lobby management

remote func _register_player(id : int, player_info : Dictionary, is_ready : bool) -> void:
	# This is the structure inside the players dictionary.
	players[id] = {
		"player_info" : player_info,
		"ready" : false,
		"loaded" : false
	}
	
	if get_tree().is_network_server() and players.size() > 1:
		for target_id in players:
			if target_id != 1:
				for ids in players:
					var pd : Dictionary = players[ids]
					rpc_id(target_id, "_register_player", ids, pd["player_info"], pd["ready"])
	
	emit_signal("player_list_changed")


func _unregister_player(id : int) -> void:
	players.erase(id)
	emit_signal("player_list_changed")


remote func ready_player(id : int, is_ready) -> void:
	players[id]["ready"] = is_ready
	
	if get_tree().is_network_server() and players.size() > 1:
		for target_id in players:
			if target_id != 1:
				rpc_id(target_id, "ready_player", id, is_ready)
		# Check if everyone is ready
		var ready_counter : int = 0
		for id in players:
			var rd : bool = players[id]["ready"]
			if rd:
				ready_counter += 1
		if players.size() > 1 and ready_counter == players.size():
			# Immediately pre initialize the game.
			rpc("_pre_initialize_game")
	
	emit_signal("player_ready_changed")

## Game management

remotesync func _pre_initialize_game() -> void:
	state = STATE_INITIALIZE
	
	if get_tree().is_network_server():
		init_timer.start()
	
	emit_signal("game_initializing")


remote func _initialize_game() -> void:
	# Server will remote call initialize game to all players except the server.
	if get_tree().is_network_server() and players.size() > 1:
		for target_id in players:
			if target_id != 1:
				rpc_id(target_id, "_initialize_game")
	
	state = STATE_GAME
	get_tree().current_scene.queue_free()
	# Change scene to stage. Stage will take over the management.
	SceneLoader.load_scene("res://scripts/gameplay/stage/stage.tscn")


remotesync func _abort_initialize_game() -> void:
	state = STATE_IDLE
	
	if get_tree().is_network_server():
		init_timer.stop()
	
	call_deferred("close_network")
	
	emit_signal("game_initializing_aborted")


remotesync func _end_game() -> void:
	state = STATE_IDLE
	
	if get_tree().current_scene.filename == "res://scripts/gameplay/stage/stage.tscn":
		get_tree().current_scene.queue_free()
		SceneLoader.load_scene("res://scripts/ui/main_menu/main_menu.tscn")
	
	call_deferred("close_network")
	
	emit_signal("game_end")
