extends Node
## TestTrialSetup - Creates a test checkpoint trial programmatically
##
## This script creates a simple 3-checkpoint trial for testing.

func _ready() -> void:
	Log.debug("TestTrialSetup: _ready() called")
	_create_test_trial()

func _create_test_trial() -> void:
	"""Create and register a test checkpoint trial"""
	Log.debug("TestTrialSetup: _create_test_trial() starting")
	var definition = TrialDefinition.new()
	Log.debug("TestTrialSetup: TrialDefinition created")
	definition.id = "test_checkpoint_1"
	definition.display_name = "Test Checkpoint Trial"
	definition.description = "Pass through 3 checkpoints in 30 seconds"
	definition.trial_type = TrialTypes.TrialType.CHECKPOINT
	definition.spawn_chunk = Vector2i(1, 0)  # East chunk
	definition.spawn_position = Vector3(100, 0, 0)
	definition.time_limit = 30.0
	definition.checkpoint_count = 3

	# Define checkpoint gates (positioned above ground at y=4)
	var gate1 = TrialObject.new()
	gate1.scene_path = "res://scenes/trials/checkpoint_gate.tscn"
	gate1.position = Vector3(110, 0, 10)
	gate1.rotation = Vector3(0, 0, 0)

	var gate2 = TrialObject.new()
	gate2.scene_path = "res://scenes/trials/checkpoint_gate.tscn"
	gate2.position = Vector3(120, 0, 25)
	gate2.rotation = Vector3(0, 45, 0)

	var gate3 = TrialObject.new()
	gate3.scene_path = "res://scenes/trials/checkpoint_gate.tscn"
	gate3.position = Vector3(130, 0, 25)
	gate3.rotation = Vector3(0, 0, 0)

	# Append objects individually to typed array
	definition.trial_objects.append(gate1)
	definition.trial_objects.append(gate2)
	definition.trial_objects.append(gate3)

	Log.debug("TestTrialSetup: Added ", definition.trial_objects.size(), " gates to trial definition")

	# Register the trial
	TrialManager.register_trial(definition)

	Log.debug("TestTrialSetup: Test trial created and registered")
