extends Node
## TrialManager - Manages trials and challenges
##
## Handles trial activation, completion, and spawning of trial objects.

var active_trial: Trial = null
var completed_trials: Array[String] = []
var spawned_objects: Array[Node3D] = []
var trial_definitions: Dictionary = {}  # trial_id -> TrialDefinition

signal trial_started(trial: Trial)
signal trial_completed(trial_id: String, success: bool)
signal trial_available(trial_id: String, position: Vector3)

func _ready() -> void:
	Log.debug("TrialManager initialized")

func _process(delta: float) -> void:
	"""Update active trial"""
	if active_trial:
		active_trial.update(delta)

func register_trial(definition: TrialDefinition) -> void:
	"""Register a trial definition"""
	if definition.id.is_empty():
		push_error("TrialManager: Cannot register trial with empty ID")
		return

	Log.debug("TrialManager: Registering trial with ", definition.trial_objects.size(), " objects")
	trial_definitions[definition.id] = definition
	Log.debug("TrialManager: Registered trial: ", definition.id, " (", definition.display_name, ")")
	Log.debug("TrialManager: Stored definition has ", trial_definitions[definition.id].trial_objects.size(), " objects")

func get_trial_definition(trial_id: String) -> TrialDefinition:
	"""Get a trial definition by ID"""
	if trial_definitions.has(trial_id):
		var def = trial_definitions[trial_id]
		Log.debug("TrialManager: Retrieved definition for ", trial_id, " has ", def.trial_objects.size(), " objects")
		return def
	Log.debug("TrialManager: No definition found for ", trial_id)
	return null

func start_trial(trial_id: String) -> bool:
	"""Start a trial by its ID"""
	Log.debug("TrialManager: start_trial called for: ", trial_id)

	# Check if another trial is active
	if active_trial != null:
		push_warning("TrialManager: Cannot start trial, another trial is active")
		return false

	# Get trial definition
	var definition = get_trial_definition(trial_id)
	if not definition:
		push_error("TrialManager: Trial definition not found: ", trial_id)
		return false

	Log.debug("TrialManager: Trial definition found, has ", definition.trial_objects.size(), " objects to spawn")

	# Check if already completed
	if is_trial_completed(trial_id):
		Log.debug("TrialManager: Trial already completed: ", trial_id)
		# Allow replay for now
		pass

	# Create trial instance
	active_trial = Trial.new(definition)
	active_trial.trial_completed.connect(_on_trial_completed)

	# Spawn trial objects
	_spawn_trial_objects(definition)

	# Start the trial
	active_trial.start()
	trial_started.emit(active_trial)

	return true

func _spawn_trial_objects(definition: TrialDefinition) -> void:
	"""Spawn all objects for a trial"""
	var spawn_parent = get_tree().current_scene
	var checkpoint_index = 0

	Log.debug("TrialManager: Starting to spawn ", definition.trial_objects.size(), " objects")

	for obj_def: TrialObject in definition.trial_objects:
		if obj_def.scene_path.is_empty():
			continue

		if not ResourceLoader.exists(obj_def.scene_path):
			push_warning("TrialManager: Object scene not found: ", obj_def.scene_path)
			continue

		var scene = load(obj_def.scene_path)
		if not scene:
			push_warning("TrialManager: Failed to load object: ", obj_def.scene_path)
			continue

		var instance = scene.instantiate()
		instance.position = obj_def.position
		instance.rotation_degrees = obj_def.rotation
		instance.scale = obj_def.scale

		# Store reference to trial in object if it supports it
		if instance.has_method("set_trial"):
			instance.set_trial(active_trial)

		# Set checkpoint index for checkpoint gates
		if instance is CheckpointGate:
			instance.checkpoint_index = checkpoint_index
			checkpoint_index += 1
			Log.debug("TrialManager: Set checkpoint index ", instance.checkpoint_index, " for gate at ", obj_def.position)

		spawn_parent.add_child(instance)
		spawned_objects.append(instance)
		Log.debug("TrialManager: Spawned object at world position: ", instance.global_position)

	Log.debug("TrialManager: Finished spawning ", spawned_objects.size(), " objects for trial: ", definition.id)

func _on_trial_completed(success: bool) -> void:
	"""Handle trial completion"""
	if not active_trial:
		return

	var trial_id = active_trial.definition.id

	if success:
		# Mark as completed
		mark_trial_completed(trial_id)

		# Award reward
		if not active_trial.definition.reward_part_id.is_empty():
			PlayerInventory.add_part(active_trial.definition.reward_part_id)
			Log.debug("TrialManager: Awarded part: ", active_trial.definition.reward_part_id)

	# Clean up
	_cleanup_trial()

	# Emit signal
	trial_completed.emit(trial_id, success)

func _cleanup_trial() -> void:
	"""Clean up spawned objects and reset state"""
	# Remove all spawned objects
	for obj in spawned_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	spawned_objects.clear()

	if is_instance_valid(active_trial):
		active_trial.queue_free()

	active_trial = null
	Log.debug("TrialManager: Trial cleaned up")

func cancel_trial() -> void:
	"""Cancel the active trial"""
	if not active_trial:
		return

	Log.debug("TrialManager: Trial cancelled: ", active_trial.definition.id)
	active_trial.fail()

func is_trial_active() -> bool:
	"""Check if a trial is currently active"""
	return active_trial != null

func is_trial_completed(trial_id: String) -> bool:
	"""Check if a trial has been completed"""
	return trial_id in completed_trials

func mark_trial_completed(trial_id: String) -> void:
	"""Mark a trial as completed"""
	if trial_id not in completed_trials:
		completed_trials.append(trial_id)
		SaveManager.save_game()  # Auto-save on trial completion
		Log.debug("TrialManager: Trial marked as completed: ", trial_id)

func get_active_trial() -> Trial:
	"""Get the currently active trial"""
	return active_trial
