extends Control
signal back


func _ready() -> void:
	pass


func _on_back() -> void:
	back()


func back() -> void:
	emit_signal("back")
	queue_free()


func _on_Back_pressed() -> void:
	_on_back()
