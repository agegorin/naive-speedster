extends Area3D
class_name TrialTrigger
## TrialTrigger - Activates a trial when player enters
##
## Displays UI prompt and starts trial when player presses interact.

@export var trial_id: String = ""
@export var auto_register: bool = true  ## Automatically create and register trial definition

## Trial configuration (only used if auto_register is true)
@export_group("Trial Setup")
@export var trial_name: String = "Unnamed Trial"
@export var trial_type: TrialTypes.TrialType = TrialTypes.TrialType.CHECKPOINT
@export var time_limit: float = 60.0
@export var checkpoint_count: int = 5

var player_in_range: bool = false
var prompt_label: Label = null

signal player_entered_range
signal player_exited_range

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Auto-register trial if enabled
	if auto_register and not trial_id.is_empty():
		_auto_register_trial()

func _auto_register_trial() -> void:
	"""Automatically create and register a simple trial"""
	var definition = TrialDefinition.new()
	definition.id = trial_id
	definition.display_name = trial_name
	definition.trial_type = trial_type
	definition.spawn_chunk = WorldManager.get_chunk_coord(global_position)
	definition.spawn_position = global_position
	definition.time_limit = time_limit
	definition.checkpoint_count = checkpoint_count

	# Note: Trial objects should be added separately or in child classes

	TrialManager.register_trial(definition)

func _process(_delta: float) -> void:
	"""Check for interact input"""
	if player_in_range and Input.is_action_just_pressed("interact"):
		_activate_trial()

func _on_body_entered(body: Node3D) -> void:
	"""Player entered trigger range"""
	if not body.is_in_group("player"):
		return

	# Check if trial is already completed
	if TrialManager.is_trial_completed(trial_id):
		return

	# Check if another trial is active
	if TrialManager.is_trial_active():
		return

	player_in_range = true
	player_entered_range.emit()
	_show_prompt()

func _on_body_exited(body: Node3D) -> void:
	"""Player exited trigger range"""
	if not body.is_in_group("player"):
		return

	player_in_range = false
	player_exited_range.emit()
	_hide_prompt()

func _show_prompt() -> void:
	"""Show interaction prompt"""
	# Emit signal that UI can listen to
	var definition = TrialManager.get_trial_definition(trial_id)
	if definition:
		Log.debug("TrialTrigger: Press [E] to start: ", definition.display_name)
		# TODO: Show actual UI prompt when UI system is ready

func _hide_prompt() -> void:
	"""Hide interaction prompt"""
	# TODO: Hide UI prompt
	pass

func _activate_trial() -> void:
	"""Activate the trial"""
	if trial_id.is_empty():
		push_error("TrialTrigger: No trial ID set")
		return

	var success = TrialManager.start_trial(trial_id)
	if success:
		_hide_prompt()
		Log.debug("TrialTrigger: Started trial: ", trial_id)
