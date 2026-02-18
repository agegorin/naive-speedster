extends Node3D
class_name FollowCamera
## FollowCamera - Smooth camera that follows vehicle with stabilization
##
## Follows vehicle's direction smoothly while staying mostly upright.

@export var target: Node3D  ## The vehicle to follow
@export var follow_distance: float = 12.0  ## Distance behind vehicle
@export var follow_height: float = 6.0  ## Height above vehicle
@export var rotation_speed: float = 3.0  ## How fast camera rotates to follow (higher = faster)
@export var banking_amount: float = 0.15  ## How much camera rolls during turns (0-1)
@export var max_pitch_angle: float = 30.0  ## Maximum pitch angle in degrees

@onready var camera: Camera3D = $Camera3D

var current_yaw: float = 0.0
var current_pitch: float = 0.0
var current_roll: float = 0.0

func _ready() -> void:
	if not target:
		# Try to find player vehicle
		target = get_tree().get_first_node_in_group("player")

	if target:
		# Initialize camera position and rotation (flipped 180° to be behind vehicle)
		var target_transform = target.global_transform
		current_yaw = atan2(target_transform.basis.z.x, target_transform.basis.z.z) + PI
		_update_camera_position()

func _physics_process(delta: float) -> void:
	if not target:
		return

	_update_camera_rotation(delta)
	_update_camera_position()

func _update_camera_rotation(delta: float) -> void:
	"""Update camera rotation to follow vehicle smoothly"""
	var target_transform = target.global_transform

	# Get vehicle's forward direction (yaw only) - flipped 180° to follow from behind
	var vehicle_forward = Vector3(target_transform.basis.z.x, 0, target_transform.basis.z.z).normalized()
	var target_yaw = atan2(vehicle_forward.x, vehicle_forward.z) + PI

	# Smoothly interpolate yaw
	var yaw_diff = _angle_difference(target_yaw, current_yaw)
	current_yaw += yaw_diff * rotation_speed * delta

	# Get vehicle's pitch (up/down angle) but clamp it - flipped because vehicle is backward
	var vehicle_up = target_transform.basis.y
	var vehicle_forward_3d = target_transform.basis.z  # Flipped: use +Z instead of -Z
	var target_pitch = asin(clamp(vehicle_forward_3d.y, -1.0, 1.0))
	target_pitch = clamp(target_pitch, deg_to_rad(-max_pitch_angle), deg_to_rad(max_pitch_angle))

	# Smoothly interpolate pitch
	current_pitch = lerp(current_pitch, target_pitch, rotation_speed * delta)

	# Calculate banking (roll) based on vehicle's angular velocity or steering
	var target_roll = 0.0
	if target is VehicleBody3D:
		# Get angular velocity around Y axis (turning)
		var angular_vel = target.angular_velocity.y
		target_roll = -angular_vel * banking_amount  # Negative for correct banking direction
		target_roll = clamp(target_roll, deg_to_rad(-20), deg_to_rad(20))

	# Smoothly interpolate roll
	current_roll = lerp(current_roll, target_roll, rotation_speed * delta * 2.0)

	# Apply rotation to camera arm
	var cam_basis = Basis()
	cam_basis = cam_basis.rotated(Vector3.UP, current_yaw)  # Yaw
	cam_basis = cam_basis.rotated(cam_basis.x, current_pitch)  # Pitch
	cam_basis = cam_basis.rotated(cam_basis.z, current_roll)  # Roll (banking)

	global_transform.basis = cam_basis

func _update_camera_position() -> void:
	"""Update camera position to stay behind vehicle"""
	if not target:
		return

	# Calculate position behind and above the vehicle
	# Camera looks along -Z, so to position it behind what it's looking at:
	# we move it along +Z (opposite of its forward direction)
	var cam_backward = global_transform.basis.z  # Opposite of camera's forward
	var target_position = target.global_position

	# Position camera behind (along +Z axis) and above (world up)
	global_position = target_position + cam_backward * follow_distance + Vector3.UP * follow_height

func _angle_difference(target: float, current: float) -> float:
	"""Calculate shortest angle difference"""
	var diff = fmod(target - current, TAU)
	if diff > PI:
		diff -= TAU
	elif diff < -PI:
		diff += TAU
	return diff
