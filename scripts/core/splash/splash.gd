extends Control

export(float, 10) var duration      : float = 2.25
export(float, 2)  var fade_duration : float = 0.8
export(float, 3) var zoom_amount    : float = 1.25

export(String, FILE, "*.tscn") var entry_point : String = ""

onready var creator_logo = $CreatorLogo
onready var engine_logo = $EngineLogo
onready var error_label = $ErrorLabel
onready var tween = $Tween


func _ready() -> void:
	# Set default clear color to in-engine splash color.
	var clear_color : Color = ProjectSettings.get("application/boot_splash/bg_color")
	VisualServer.set_default_clear_color(clear_color)
	
	# Set own opacity to 0
	modulate.a = 0
	
	# Hide error label just in case if it's not hidden
	error_label.hide()
	
	# Set up fade tweens
	tween.interpolate_property(
		self, "modulate:a",
		0, 1, fade_duration
	)
	tween.interpolate_property(
		self, "modulate:a",
		1, 0, fade_duration,
		Tween.TRANS_LINEAR, Tween.EASE_OUT,
		duration - fade_duration
	)
	tween.start()
	
	# Set up timer
	var tep_timer = Timer.new()
	tep_timer.one_shot = true
	tep_timer.wait_time = duration
	tep_timer.connect("timeout", self, "_on_timer_timeout")
	add_child(tep_timer)
	tep_timer.start()


func _on_timer_timeout() -> void:
	# Change scene to defined entry point scene, BUT FIRST!!
	
	# Hide all, but show ErrorLabel
	creator_logo.hide()
	engine_logo.hide()
	error_label.show()
	
	# Check if a scene is defined
	if entry_point.empty():
		modulate.a = 1
		error_label.text = "No scene entry point defined. THERE IS NO GAME!!"
		return
	
	# Check if a scene loops back to this scene
	if entry_point == filename:
		modulate.a = 1
		error_label.text = "You can't just link back to this scene! That is illegal!"
		return
	
	# FINALLY, if no errors, run the scene
	SceneLoader.load_scene(entry_point)
	
	yield(SceneLoader, "done")
	
	# Set clear color back to default.
	var clear_color : Color = ProjectSettings.get("rendering/environment/default_clear_color")
	VisualServer.set_default_clear_color(clear_color)
	
	queue_free()


func _process(delta: float) -> void:
	var za : float = (zoom_amount / 100) * delta
	creator_logo.scale += Vector2(za, za)
