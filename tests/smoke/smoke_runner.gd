extends Node

const PLAYER_SCENE: PackedScene = preload("res://scenes/vehicle/player_vehicle.tscn")
const CHECKPOINT_SCENE_PATH := "res://scenes/trials/checkpoint_gate.tscn"

var _passed: int = 0
var _failed: Array[String] = []

func _ready() -> void:
	await get_tree().process_frame
	await _run_all()
	await _finish()

func _run_all() -> void:
	await _run_case("test_autoloads_available", _test_autoloads_available)
	await _run_case("test_player_detection_and_initial_chunk_load", _test_player_detection_and_initial_chunk_load)
	await _run_case("test_chunk_streaming_on_player_move", _test_chunk_streaming_on_player_move)
	await _run_case("test_trial_start_spawns_objects", _test_trial_start_spawns_objects)
	await _run_case("test_trial_cancel_cleans_state", _test_trial_cancel_cleans_state)
	await _run_case("test_trial_completion_updates_progress_and_reward", _test_trial_completion_updates_progress_and_reward)
	await _run_case("test_flip_recovery_sequence", _test_flip_recovery_sequence)

func _run_case(case_name: String, test_callable: Callable) -> void:
	await _before_each()
	Log.info("[SMOKE] Running ", case_name)
	await test_callable.call()
	await _after_each()

func _before_each() -> void:
	_clear_players()
	WorldManager.clear_all_chunks()
	WorldManager.player_ref = null
	WorldManager.player_chunk = Vector2i.ZERO

	if TrialManager.is_trial_active():
		TrialManager.cancel_trial()
		await get_tree().process_frame

	for spawned in TrialManager.spawned_objects:
		if is_instance_valid(spawned):
			spawned.queue_free()

	TrialManager.trial_definitions.clear()
	TrialManager.completed_trials.clear()
	TrialManager.spawned_objects.clear()
	TrialManager.active_trial = null

	PlayerInventory.unlocked_parts.clear()
	PlayerInventory.equipped_parts = {
		"engine": null,
		"wheels": null,
		"body": null
	}

	await get_tree().process_frame

func _after_each() -> void:
	_clear_players()
	WorldManager.clear_all_chunks()

	if TrialManager.is_trial_active():
		TrialManager.cancel_trial()
		await get_tree().process_frame

	for spawned in TrialManager.spawned_objects:
		if is_instance_valid(spawned):
			spawned.queue_free()

	TrialManager.trial_definitions.clear()
	TrialManager.completed_trials.clear()
	TrialManager.spawned_objects.clear()
	TrialManager.active_trial = null
	await get_tree().process_frame

func _clear_players() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node):
			node.queue_free()

func _spawn_player(at_position: Vector3):
	var player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = at_position
	return player

func _wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		Log.info("[PASS] ", message)
	else:
		_failed.append(message)
		Log.info("[FAIL] ", message)

func _test_autoloads_available() -> void:
	_check(SaveManager != null, "SaveManager autoload is available")
	_check(PlayerInventory != null, "PlayerInventory autoload is available")
	_check(GameManager != null, "GameManager autoload is available")
	_check(WorldManager != null, "WorldManager autoload is available")
	_check(TrialManager != null, "TrialManager autoload is available")

func _test_player_detection_and_initial_chunk_load() -> void:
	var player = _spawn_player(Vector3(0, 3, 0))
	await _wait_seconds(0.7)

	_check(WorldManager.player_ref == player, "WorldManager detected player reference")
	_check(WorldManager.loaded_chunks.size() > 0, "Initial chunks loaded around player")
	_check(
		WorldManager.loaded_chunks.has(WorldManager.get_chunk_coord(player.global_position)),
		"Current player chunk is loaded"
	)

func _test_chunk_streaming_on_player_move() -> void:
	var player = _spawn_player(Vector3(0, 3, 0))
	await _wait_seconds(0.7)

	var target_chunk := Vector2i(1, 0)
	player.global_position = WorldManager.get_chunk_world_position(target_chunk) + Vector3(5, 3, 5)
	WorldManager.update_chunks(player.global_position)
	await get_tree().process_frame

	_check(WorldManager.player_chunk == target_chunk, "Player chunk coordinate updated after move")

func _test_trial_start_spawns_objects() -> void:
	var definition = _make_trial_definition("smoke_trial_start")
	TrialManager.register_trial(definition)

	var started = TrialManager.start_trial(definition.id)
	await get_tree().process_frame

	_check(started, "Trial start returned true")
	_check(TrialManager.is_trial_active(), "TrialManager reports active trial")
	_check(TrialManager.spawned_objects.size() == 1, "Trial spawned one checkpoint object")

func _test_trial_cancel_cleans_state() -> void:
	var definition = _make_trial_definition("smoke_trial_cancel")
	TrialManager.register_trial(definition)
	TrialManager.start_trial(definition.id)
	await get_tree().process_frame

	TrialManager.cancel_trial()
	await get_tree().process_frame

	_check(not TrialManager.is_trial_active(), "Trial is not active after cancel")
	_check(TrialManager.spawned_objects.is_empty(), "Spawned objects list is cleared on cancel")

func _test_trial_completion_updates_progress_and_reward() -> void:
	var definition = _make_trial_definition("smoke_trial_complete")
	definition.reward_part_id = "reward_engine_smoke"
	TrialManager.register_trial(definition)
	TrialManager.start_trial(definition.id)

	var trial = TrialManager.get_active_trial()
	trial.pass_checkpoint(0)
	await get_tree().process_frame

	_check(TrialManager.is_trial_completed(definition.id), "Completed trial is tracked in TrialManager")
	_check(PlayerInventory.has_part("reward_engine_smoke"), "Reward part added to inventory")

func _test_flip_recovery_sequence() -> void:
	var player = _spawn_player(Vector3(0, 5, 0))
	player.flip_timeout = 0.0
	player.recovery_duration = 0.05
	player.recovery_height = 1.0
	player.global_transform = Transform3D(Basis(Vector3.RIGHT, PI), player.global_position)
	await get_tree().process_frame

	player._check_flip_status(0.1)
	_check(player.is_recovering, "Flip recovery starts when vehicle is upside down")

	player._handle_recovery(0.1)
	player._handle_recovery(0.1)

	_check(not player.is_recovering, "Flip recovery sequence completes")
	_check(not player.freeze, "Vehicle physics is unfrozen after recovery")
	_check(player.linear_velocity == Vector3.ZERO, "Linear velocity reset after recovery")
	_check(player.angular_velocity == Vector3.ZERO, "Angular velocity reset after recovery")

func _make_trial_definition(trial_id: String) -> TrialDefinition:
	var definition = TrialDefinition.new()
	definition.id = trial_id
	definition.display_name = trial_id
	definition.trial_type = TrialTypes.TrialType.CHECKPOINT
	definition.time_limit = 30.0
	definition.checkpoint_count = 1

	var gate = TrialObject.new()
	gate.scene_path = CHECKPOINT_SCENE_PATH
	gate.position = Vector3(0, 0, 0)
	definition.trial_objects.append(gate)

	return definition

func _finish() -> void:
	_clear_players()
	WorldManager.clear_all_chunks()
	WorldManager.loading_chunks.clear()
	TrialManager.trial_definitions.clear()
	TrialManager.completed_trials.clear()
	TrialManager.spawned_objects.clear()
	TrialManager.active_trial = null
	await get_tree().process_frame
	await get_tree().process_frame

	if _failed.is_empty():
		Log.info("[SMOKE] All checks passed: ", _passed)
		get_tree().quit(0)
		return

	Log.info("[SMOKE] Failed checks: ", _failed.size(), " / Passed checks: ", _passed)
	for failure in _failed:
		Log.info("[SMOKE] - ", failure)
	get_tree().quit(1)
