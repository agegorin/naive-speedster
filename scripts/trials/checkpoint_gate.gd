extends Area3D
class_name CheckpointGate
## CheckpointGate - A gate/checkpoint for trials
##
## Detects when player passes through and notifies the trial.

@export var checkpoint_index: int = 0
@export var gate_color: Color = Color.WHITE

var trial: Trial = null
var is_passed: bool = false
var visual_mesh: MeshInstance3D = null

signal checkpoint_passed(index: int)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_visuals()
	print("CheckpointGate ready at position: ", global_position, " index: ", checkpoint_index)

func _setup_visuals() -> void:
	"""Setup visual appearance"""
	# Find mesh if it exists
	visual_mesh = get_node_or_null("Visual/Mesh")
	if visual_mesh and visual_mesh.get_surface_override_material_count() > 0:
		var mat = visual_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = gate_color

func set_trial(active_trial: Trial) -> void:
	"""Set the trial this gate belongs to"""
	trial = active_trial

func _on_body_entered(body: Node3D) -> void:
	"""Detect player passing through gate"""
	if is_passed:
		return

	# Check if it's the player
	if not body.is_in_group("player"):
		return

	# Check if trial is active
	if not trial or trial.status != TrialTypes.TrialStatus.ACTIVE:
		return

	# Check if this is the next checkpoint
	if checkpoint_index != trial.current_checkpoint:
		print("CheckpointGate: Wrong checkpoint order! Expected ", trial.current_checkpoint, " got ", checkpoint_index)
		return

	# Mark as passed
	is_passed = true
	trial.pass_checkpoint(checkpoint_index)
	checkpoint_passed.emit(checkpoint_index)

	# Visual feedback
	_show_passed_effect()

func _show_passed_effect() -> void:
	"""Show visual effect when passed"""
	if visual_mesh:
		# Make it transparent/green
		var mat = visual_mesh.get_surface_override_material(0)
		if mat is StandardMaterial3D:
			mat.albedo_color = Color(0, 1, 0, 0.3)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func reset() -> void:
	"""Reset the checkpoint for replay"""
	is_passed = false
	_setup_visuals()
