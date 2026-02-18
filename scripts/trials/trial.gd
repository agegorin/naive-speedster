extends Node
class_name Trial
## Trial - Runtime instance of an active trial
##
## Manages the state and logic of a currently running trial.

var definition: TrialDefinition
var status: TrialTypes.TrialStatus = TrialTypes.TrialStatus.NOT_STARTED
var time_elapsed: float = 0.0
var checkpoints_passed: int = 0
var current_checkpoint: int = 0

signal trial_started
signal trial_completed(success: bool)
signal checkpoint_passed(index: int, total: int)
signal time_updated(elapsed: float, remaining: float)

func _init(trial_def: TrialDefinition) -> void:
	definition = trial_def

func start() -> void:
	"""Start the trial"""
	status = TrialTypes.TrialStatus.ACTIVE
	time_elapsed = 0.0
	checkpoints_passed = 0
	current_checkpoint = 0
	trial_started.emit()
	print("Trial started: ", definition.display_name)

func update(delta: float) -> void:
	"""Update trial logic"""
	if status != TrialTypes.TrialStatus.ACTIVE:
		return

	time_elapsed += delta

	# Check time limit for checkpoint trials
	if definition.trial_type == TrialTypes.TrialType.CHECKPOINT:
		var remaining = definition.time_limit - time_elapsed
		time_updated.emit(time_elapsed, remaining)

		if remaining <= 0:
			fail()

func pass_checkpoint(index: int) -> void:
	"""Mark a checkpoint as passed"""
	if status != TrialTypes.TrialStatus.ACTIVE:
		return

	checkpoints_passed += 1
	current_checkpoint = index + 1
	checkpoint_passed.emit(index, definition.checkpoint_count)
	print("Checkpoint passed: ", index + 1, "/", definition.checkpoint_count)

	# Check if all checkpoints passed
	if checkpoints_passed >= definition.checkpoint_count:
		complete()

func complete() -> void:
	"""Complete the trial successfully"""
	if status != TrialTypes.TrialStatus.ACTIVE:
		return

	status = TrialTypes.TrialStatus.COMPLETED
	trial_completed.emit(true)
	print("Trial completed: ", definition.display_name)

func fail() -> void:
	"""Fail the trial"""
	if status != TrialTypes.TrialStatus.ACTIVE:
		return

	status = TrialTypes.TrialStatus.FAILED
	trial_completed.emit(false)
	print("Trial failed: ", definition.display_name)

func get_time_remaining() -> float:
	"""Get remaining time for checkpoint trials"""
	if definition.trial_type == TrialTypes.TrialType.CHECKPOINT:
		return max(0.0, definition.time_limit - time_elapsed)
	return 0.0
