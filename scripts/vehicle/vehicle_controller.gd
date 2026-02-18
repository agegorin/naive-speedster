extends VehicleBody3D
## VehicleController - Handles player vehicle input and physics
##
## Controls the vehicle based on player input and applies physics forces.

@export_group("Vehicle Stats")
@export var max_engine_force: float = 200.0
@export var max_brake_force: float = 5.0
@export var max_steering_angle: float = 0.5
@export var steering_speed: float = 2.0

@export_group("Flip Recovery")
@export var flip_detection_angle: float = 120.0  ## Angle in degrees to consider car flipped
@export var flip_timeout: float = 1.0  ## Time in seconds before auto-recovery
@export var recovery_height: float = 2.0  ## Height to lift car during recovery
@export var recovery_duration: float = 0.5  ## Duration of recovery animation

var current_steering: float = 0.0

# Flip recovery state
var is_upside_down: bool = false
var upside_down_timer: float = 0.0
var is_recovering: bool = false
var recovery_timer: float = 0.0
var recovery_start_transform: Transform3D
var recovery_target_transform: Transform3D

func _ready() -> void:
	print("VehicleController initialized")

func _physics_process(delta: float) -> void:
	if is_recovering:
		_handle_recovery(delta)
	else:
		_check_flip_status(delta)
		_handle_input(delta)

func _handle_input(delta: float) -> void:
	"""Process player input and apply to vehicle"""
	# Acceleration/Braking
	var accelerate_input = Input.get_action_strength("accelerate")
	var brake_input = Input.get_action_strength("brake")

	if accelerate_input > 0:
		engine_force = max_engine_force * accelerate_input
		brake = 0
	elif brake_input > 0:
		engine_force = 0
		brake = max_brake_force * brake_input
	else:
		engine_force = 0
		brake = 0.5  # Light brake when no input

	# Steering
	var steer_input = Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	current_steering = lerp(current_steering, -steer_input * max_steering_angle, steering_speed * delta)
	steering = current_steering

func _check_flip_status(delta: float) -> void:
	"""Check if car is upside down and start recovery if needed"""
	# Check if car is upside down based on up vector
	var up_direction = global_transform.basis.y
	var angle_from_upright = rad_to_deg(acos(up_direction.dot(Vector3.UP)))

	# Car is upside down if tilted more than the threshold
	if angle_from_upright > flip_detection_angle:
		if not is_upside_down:
			is_upside_down = true
			upside_down_timer = 0.0
			print("Vehicle flipped! Starting recovery timer...")

		upside_down_timer += delta

		# Start recovery if timeout reached
		if upside_down_timer >= flip_timeout:
			_start_recovery()
	else:
		# Reset if car is upright
		is_upside_down = false
		upside_down_timer = 0.0

func _start_recovery() -> void:
	"""Begin the flip recovery sequence"""
	print("Starting flip recovery...")
	is_recovering = true
	recovery_timer = 0.0

	# Disable physics
	freeze = true

	# Store current transform
	recovery_start_transform = global_transform

	# Calculate target transform
	recovery_target_transform = Transform3D()

	# Keep XZ position, lift Y position
	var target_position = global_position
	target_position.y += recovery_height

	# Use raycast to find ground below and adjust Y
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 5,
		global_position + Vector3.DOWN * 50
	)
	var result = space_state.intersect_ray(query)
	if result:
		target_position.y = result.position.y + recovery_height

	recovery_target_transform.origin = target_position

	# Calculate upright rotation (keep yaw, reset pitch and roll)
	var current_yaw = atan2(global_transform.basis.z.x, global_transform.basis.z.z)
	recovery_target_transform.basis = Basis()
	recovery_target_transform.basis = recovery_target_transform.basis.rotated(Vector3.UP, current_yaw)

func _handle_recovery(delta: float) -> void:
	"""Handle the smooth recovery animation"""
	recovery_timer += delta
	var progress = min(recovery_timer / recovery_duration, 1.0)

	# Smooth interpolation using ease-out
	var ease_progress = 1.0 - pow(1.0 - progress, 3.0)

	# Interpolate position
	global_position = recovery_start_transform.origin.lerp(
		recovery_target_transform.origin,
		ease_progress
	)

	# Interpolate rotation using quaternions for smooth rotation
	var start_quat = Quaternion(recovery_start_transform.basis)
	var target_quat = Quaternion(recovery_target_transform.basis)
	var current_quat = start_quat.slerp(target_quat, ease_progress)
	global_transform.basis = Basis(current_quat)

	# Complete recovery
	if progress >= 1.0:
		_complete_recovery()

func _complete_recovery() -> void:
	"""Complete the recovery and re-enable controls"""
	print("Flip recovery complete!")

	# Re-enable physics
	freeze = false

	# Reset velocities to prevent sudden movement
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

	# Reset state
	is_recovering = false
	is_upside_down = false
	upside_down_timer = 0.0
