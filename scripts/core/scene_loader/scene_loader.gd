extends Node
signal started
signal done

var thread : Thread


func _ready() -> void:
	pass


func _thread_load(path : String) -> void:
	var ril : ResourceInteractiveLoader = ResourceLoader.load_interactive(path, "PackedScene")
	var scene : PackedScene
	var stages : int = ril.get_stage_count()
	
	while true:
		var err = ril.poll()
		if err == ERR_FILE_EOF:
			scene = ril.get_resource()
			break
		elif err != OK:
			# Print error message with an error code.
			print("Error when loading (error code " + str(err) + ")")
	
	# Call function with loaded (or not loaded) scene.
	call_deferred("_thread_load_done", scene)


func _thread_load_done(scene : PackedScene) -> void:
	thread.wait_to_finish()
	
	var scene_ins = scene.instance()
	get_node("/root").add_child(scene_ins)
	
	get_tree().current_scene = scene_ins
	
	emit_signal("done")


func load_scene(path : String) -> void:
	thread = Thread.new()
	thread.start(self, "_thread_load", path)
	
	emit_signal("started")
