extends RigidBody2D

export var speed : float = 600

onready var sprite = $Sprite
onready var trail = $Trail
onready var arrow = $Arrow

onready var look_at_node = $LookAt
onready var player_name = $PlayerName

onready var dash_timer = $DashTimer              # Dash timer.
onready var dash_cd_timer = $DashCooldownTimer   # Dash cooldown timer.
onready var stun_timer = $StunTimer              # Stun timer.

onready var debug_label = $DebugLabel

# To avoid errors
var is_master : bool = false

# It's not like I'm creating a server everytime I want to test the player.
var test_mode : bool = false

var la_rot : float
var vel : Vector2

var is_dashing : bool = false
var is_stunned : bool = false


func _ready() -> void:
	if Network.enet:
		# Check if this player is a master or a puppet
		is_master = is_network_master()
	
	if get_tree().current_scene == self:
		# If this is the current scene, enable test mode.
		test_mode = true
	
	trail.emitting = false
	arrow.visible = is_master or test_mode
	debug_label.visible = is_master or test_mode


func _process(delta: float) -> void:
	if is_master or test_mode:
		debug_label.text = str(is_dashing) + ", " + str(dash_timer.time_left) + ", " + str(int(dash_cd_timer.time_left))


func _physics_process(delta: float) -> void:
	if is_master or test_mode:
		# Update arrow rotation, but with lerp
		arrow.rotation = lerp_angle(arrow.rotation, la_rot, 0.175)
		# Do movement
		if is_stunned:
			if stun_timer.time_left == 0:
				is_stunned = false
				modulate.v = 1
		else:
			move()
		
		if Network.enet:
			# Send state every physics process. I don't know if this is a good idea or not.
			rpc_unreliable("_set_state", position, linear_velocity, applied_force, modulate, trail.emitting)

# Set state of player. Sent to puppet nodes.
puppet func _set_state(pos : Vector2, vel : Vector2, force : Vector2, mod : Color, t_emit : bool) -> void:
	position = pos
	linear_velocity = vel
	applied_force = force
	modulate = mod
	trail.emitting = t_emit


# Normal move
func move() -> void:
	vel = Vector2(cos(la_rot), sin(la_rot))
	
	if Input.is_action_just_pressed("dash") and dash_cd_timer.time_left == 0 and not is_dashing:
		is_dashing = true
		trail.emitting = true
		dash_timer.start()
	
	if is_dashing:
		# Not applying rotation here, effectively freezing the rotation.
		linear_velocity = vel * speed * 1.5
		
		if dash_timer.is_stopped():
			is_dashing = false
			trail.emitting = false
			dash_cd_timer.start()
	else:
		la_rot = look_at_node.rotation
		applied_force = vel * speed


# Stun this player, likely be called from another player.
remote func stun(id : int = 0) -> void:
	if not is_network_master():
		rpc_id(id, "stun")
	else:
		is_stunned = true
		applied_force = Vector2.ZERO
		modulate.v = 0.5
		stun_timer.start()


func _on_Player_body_entered(body: Node) -> void:
	# Stop dash if player hits anything.
	if is_network_master():
		if is_dashing:
			if body.is_in_group("player"):
				body.stun(body.get_network_master())
			dash_timer.stop()


func _on_PlayerDetectorBody_body_entered(body: Node) -> void:
	pass
