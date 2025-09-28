extends CharacterBody3D

const SPEED = 10.0
const JUMP_VELOCITY = 8
var sensitivity = 0.004

# Health/Block system variables
var max_blocks = 10  # Maximum blocks allowed
var current_blocks = 10  # Current blocks remaining
var is_dead = false

@onready var camera_3d = $Camera3D
@onready var ray_cast_3d: RayCast3D = $Camera3D/RayCast3D

# Signal to update UI
signal blocks_changed(current_blocks, max_blocks)
signal player_died()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Initialize UI
	emit_signal("blocks_changed", current_blocks, max_blocks)

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func check_water_collision():
	# If water is at Y = 0, die when player goes below 1.0
	if global_position.y < 3.0:
		die()
		
func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * 1.75 * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	# Block interactions
	if Input.is_action_just_pressed("left_click"):
		if ray_cast_3d.is_colliding():
			if ray_cast_3d.get_collider().has_method("destroy_block"):
				ray_cast_3d.get_collider().destroy_block(ray_cast_3d.get_collision_point() - ray_cast_3d.get_collision_normal())
				# Increase block allowance when breaking a block
				current_blocks += 1
				current_blocks = min(current_blocks, max_blocks)  # Don't exceed max
				emit_signal("blocks_changed", current_blocks, max_blocks)

	if Input.is_action_just_pressed("right_click"):
		if current_blocks > 0:  # Only place if we have blocks remaining
			if ray_cast_3d.is_colliding():
				if ray_cast_3d.get_collider().has_method("place_block"):
					ray_cast_3d.get_collider().place_block(ray_cast_3d.get_collision_point() + ray_cast_3d.get_collision_normal(), 5)
					# Decrease block allowance when placing a block
					current_blocks -= 1
					emit_signal("blocks_changed", current_blocks, max_blocks)
					
					# Check for death
					if current_blocks <= 0:
						die()
	check_water_collision()
	move_and_slide()

func _unhandled_input(event):
	if is_dead:
		return
		
	if event is InputEventMouseMotion:
		rotation.y = rotation.y - event.relative.x * sensitivity
		camera_3d.rotation.x = camera_3d.rotation.x - event.relative.y * sensitivity

func die():
	is_dead = true
	get_tree().quit()
	
	# You can add death effects here:
	# - Play death animation
	# - Show death screen
	# - Restart level after delay
	
	# Example: Restart after 2 seconds
	# await get_tree().create_timer(2.0).timeout
	# get_tree().reload_current_scene()

# Optional: Function to add blocks (if you want power-ups later)
func add_blocks(amount):
	current_blocks += amount
	current_blocks = min(current_blocks, max_blocks)
	emit_signal("blocks_changed", current_blocks, max_blocks)
