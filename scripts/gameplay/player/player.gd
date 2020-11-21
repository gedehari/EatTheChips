extends RigidBody2D

export var speed : float = 600

onready var sprite = $Sprite
onready var look_at_node = $LookAt
onready var arrow = $Arrow
onready var dash_timer = $DashTimer              # Dash timer
onready var dash_cd_timer = $DashCooldownTimer   # Dash cooldown timer.

onready var debug_label = $DebugLabel

var la_rot : float
var vel : Vector2

var is_dashing : bool = false


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	debug_label.text = str(is_dashing) + ", " + str(dash_timer.time_left) + ", " + str(int(dash_cd_timer.time_left))


func _physics_process(delta: float) -> void:
	# Update arrow rotation, but with lerp
	arrow.rotation = lerp_angle(arrow.rotation, la_rot, 0.175)
	
	move()


func move() -> void:
	vel = Vector2(cos(la_rot), sin(la_rot))
	
	if Input.is_action_just_pressed("dash") and dash_cd_timer.time_left == 0 and not is_dashing:
		is_dashing = true
		dash_timer.start()
	
	if is_dashing:
		# Not applying rotation here, effectively freezing the rotation here.
		linear_velocity = vel * speed * 1.5
		
		if dash_timer.is_stopped():
			is_dashing = false
			dash_cd_timer.start()
	else:
		la_rot = look_at_node.rotation
		applied_force = vel * speed


func _on_Player_body_entered(body: Node) -> void:
	dash_timer.stop()
