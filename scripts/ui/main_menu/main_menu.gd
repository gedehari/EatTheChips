extends Control

var screens : Dictionary = {
	"lol" : null
}


func _ready() -> void:
	get_tree().connect("connected_to_server", self, "_on_connected")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	
	Network.connect("player_list_changed", self, "_update_lobby")
	Network.connect("player_ready_changed", self, "_update_player_ready")
	Network.connect("game_initializing", self, "_on_game_initializing")
	
	#BGM.play_bgm("menu")
	
	$Choices.show()
	$Lobby.hide()
	
	$Lobby/Status.hide()


func _to_lobby() -> void:
	$Choices/HostBtn.disabled = false
	$Choices/JoinBtn.disabled = false
	
	$Choices.hide()
	$Lobby.show()


func _on_HostBtn_pressed() -> void:
	if $Choices/NameField.text.empty():
		return
	
	Global.player_info["name"] = $Choices/NameField.text
	
	Network.create_server()
	
	_to_lobby()


func _on_JoinBtn_pressed() -> void:
	if $Choices/NameField.text.empty():
		return
	
	Global.player_info["name"] = $Choices/NameField.text
	
	Network.join_server("127.0.0.1")
	
	$Choices/HostBtn.disabled = true
	$Choices/JoinBtn.disabled = true


func _on_connected() -> void:
	_to_lobby()


func _on_connection_failed() -> void:
	$Choices/HostBtn.disabled = false
	$Choices/JoinBtn.disabled = false

## Lobby crap

func _update_lobby() -> void:
	var text : String = "Connected players:"
	
	for player in Network.players:
		var p_name = Network.players[player]["player_info"]["name"]
		var p_ready = Network.players[player]["ready"]
		
		text += "\n" + p_name
		
		if player == get_tree().get_network_unique_id():
			text += " (You)"
		
		if p_ready:
			text += " (Ready)"
	
	$Lobby/PlayerList.text = text
	
	# Set default status text. Only server will see this since
	# logically server start with one player, which is the host.
	var status_text : String = "Cannot start a game with only yourself."
	
	# Everyone sees this
	if Network.players.size() > 1:
		status_text = "Waiting for players to ready up..."
	
	$Lobby/Status.text = status_text


func _update_player_ready() -> void:
	# Temporary, will be replaced by something better
	_update_lobby()


func _on_game_initializing() -> void:
	$Lobby/ReadyBtn.disabled = true
	
	yield(get_tree(), "idle_frame")
	$Lobby/Status.text = "Starting game..."


func _on_ReadyBtn_toggled(button_pressed: bool) -> void:
	if get_tree().is_network_server():
		Network.ready_player(1, button_pressed)
	else:
		Network.rpc_id(1, "ready_player", get_tree().get_network_unique_id(), button_pressed)
	
	$Lobby/Status.visible = button_pressed
