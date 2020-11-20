extends Node

var bgm_player : AudioStreamPlayer
var tween      : Tween

var busy : bool = false

# Define BGM here.
var bgms : Dictionary = {
	# TODO: add bgm, i cant make music :(
}


func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	add_child(bgm_player)
	
	tween = Tween.new()
	tween.name = "Tween"
	add_child(tween)
	
	bgm_player.volume_db = linear2db(0)


func play_bgm(bgm_name : String, fade_time : float = 1) -> void:
	if busy: return
	if bgm_player.stream and bgm_player.stream.resource_path == bgms[bgm_name].resource_path:
		return
	
	busy = true
	
	if bgm_player.playing:
		tween.interpolate_property(bgm_player, "volume_db", linear2db(1), linear2db(0.01), fade_time)
		tween.start()
		yield(tween, "tween_all_completed")
	
	bgm_player.stream = bgms[bgm_name]
	bgm_player.play()
	
	tween.interpolate_property(bgm_player, "volume_db", linear2db(0.005), linear2db(1), fade_time)
	tween.start()
	
	busy = false


func stop_bgm(fade_time : float = 1) -> void:
	if busy: return
	if not bgm_player.playing: return
	
	busy = true
	
	tween.interpolate_property(bgm_player, "volume_db", linear2db(1), linear2db(0.01), fade_time)
	tween.start()
	yield(tween, "tween_all_completed")
	
	bgm_player.stop()
	bgm_player.stream = null
	
	busy = false
