extends Node
## WorldManager - Manages world chunks and streaming
##
## Handles dynamic loading/unloading of world chunks based on player position.

const CHUNK_SIZE: float = 100.0
const LOAD_RADIUS: int = 2  # Load chunks within this many chunks of player
const CACHE_SIZE: int = 5  # Maximum cached chunks
const UPDATE_INTERVAL: float = 0.5  # Seconds between chunk updates

var loaded_chunks: Dictionary = {}  # Vector2i -> Node3D
var chunk_cache: Dictionary = {}  # Vector2i -> Node3D (unloaded but cached)
var loading_chunks: Dictionary = {}  # Vector2i -> ResourceLoader thread status
var player_chunk: Vector2i = Vector2i.ZERO
var player_ref: Node3D = null

var update_timer: float = 0.0

func _ready() -> void:
	Log.debug("WorldManager initialized")
	# Find player after a short delay to ensure it's spawned
	call_deferred("_find_player")

func _find_player() -> void:
	"""Find the player vehicle in the scene"""
	while true:
		player_ref = get_tree().get_first_node_in_group("player")
		if not player_ref:
			# Try to find by name
			var root = get_tree().current_scene
			if root:
				player_ref = root.find_child("PlayerVehicle", true, false)

		if player_ref:
			Log.debug("WorldManager: Player found at position: ", player_ref.global_position)

			# Freeze player physics until chunks are loaded
			if player_ref is RigidBody3D:
				player_ref.freeze = true
				Log.debug("WorldManager: Player frozen")

			# Load initial chunks synchronously to prevent falling
			_load_initial_chunks(player_ref.global_position)

			# Wait one frame for physics to register
			await get_tree().process_frame

			# Unfreeze player
			if player_ref is RigidBody3D:
				player_ref.freeze = false
				Log.debug("WorldManager: Player unfrozen")
			return

		Log.debug("WorldManager: Player not found, retrying...")
		await get_tree().create_timer(0.5).timeout

func _load_initial_chunks(player_position: Vector3) -> void:
	"""Load initial chunks synchronously around player spawn point"""
	var current_chunk = get_chunk_coord(player_position)
	player_chunk = current_chunk

	Log.debug("WorldManager: Loading initial chunks around ", current_chunk)

	# Load all chunks within radius synchronously
	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var coord = current_chunk + Vector2i(x, y)
			_load_chunk_sync(coord)

	Log.debug("WorldManager: Initial chunks loaded: ", loaded_chunks.size())

func _process(delta: float) -> void:
	"""Update chunk loading based on player position"""
	if not player_ref:
		return

	update_timer += delta
	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		update_chunks(player_ref.global_position)

	# Process async loading
	_process_loading_chunks()

func _process_loading_chunks() -> void:
	"""Check status of chunks being loaded asynchronously"""
	var to_remove: Array[Vector2i] = []
	for coord in loading_chunks.keys():
		var path = loading_chunks[coord]
		var status = ResourceLoader.load_threaded_get_status(path)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(path)
			if scene:
				_instantiate_chunk(coord, scene)
			to_remove.append(coord)
		elif status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED:
			Log.debug("WorldManager: Failed to load chunk at ", coord)
			to_remove.append(coord)

	for coord in to_remove:
		loading_chunks.erase(coord)

func get_chunk_coord(world_position: Vector3) -> Vector2i:
	"""Convert world position to chunk coordinate"""
	return Vector2i(
		int(floor(world_position.x / CHUNK_SIZE)),
		int(floor(world_position.z / CHUNK_SIZE))
	)

func get_chunk_world_position(chunk_coord: Vector2i) -> Vector3:
	"""Convert chunk coordinate to world position (center of chunk)"""
	return Vector3(
		chunk_coord.x * CHUNK_SIZE,
		0,
		chunk_coord.y * CHUNK_SIZE
	)

func get_chunk_path(chunk_coord: Vector2i) -> String:
	"""Get the scene path for a chunk coordinate"""
	return "res://scenes/world/chunks/chunk_%d_%d.tscn" % [chunk_coord.x, chunk_coord.y]

func update_chunks(player_position: Vector3) -> void:
	"""Update loaded chunks based on player position"""
	var current_chunk = get_chunk_coord(player_position)

	# Only update if player moved to a different chunk
	if current_chunk == player_chunk:
		return

	player_chunk = current_chunk

	# Determine which chunks should be loaded
	var required_chunks: Array[Vector2i] = []
	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			required_chunks.append(current_chunk + Vector2i(x, y))

	# Load missing chunks
	for coord in required_chunks:
		if not loaded_chunks.has(coord) and not loading_chunks.has(coord):
			load_chunk(coord)

	# Unload distant chunks
	var chunks_to_unload: Array[Vector2i] = []
	for coord in loaded_chunks.keys():
		if coord not in required_chunks:
			chunks_to_unload.append(coord)

	for coord in chunks_to_unload:
		unload_chunk(coord)

func _load_chunk_sync(chunk_coord: Vector2i) -> void:
	"""Load a chunk synchronously (for initial loading)"""
	# Check if already loaded
	if loaded_chunks.has(chunk_coord):
		return

	# Check if it's in cache first
	if chunk_cache.has(chunk_coord):
		var cached_chunk = chunk_cache[chunk_coord]
		chunk_cache.erase(chunk_coord)
		loaded_chunks[chunk_coord] = cached_chunk
		get_tree().current_scene.add_child(cached_chunk)
		Log.debug("WorldManager: Loaded chunk from cache: ", chunk_coord)
		return

	# Check if chunk file exists
	var path = get_chunk_path(chunk_coord)
	if not ResourceLoader.exists(path):
		# Chunk doesn't exist, skip it
		return

	# Load synchronously
	var scene = load(path)
	if scene:
		_instantiate_chunk(chunk_coord, scene)
		Log.debug("WorldManager: Loaded chunk synchronously: ", chunk_coord)
	else:
		Log.debug("WorldManager: Failed to load chunk: ", chunk_coord)

func load_chunk(chunk_coord: Vector2i) -> void:
	"""Load a chunk at the given coordinate (asynchronously)"""
	# Check if already loaded or loading
	if loaded_chunks.has(chunk_coord) or loading_chunks.has(chunk_coord):
		return

	# Check if it's in cache first
	if chunk_cache.has(chunk_coord):
		var cached_chunk = chunk_cache[chunk_coord]
		chunk_cache.erase(chunk_coord)
		loaded_chunks[chunk_coord] = cached_chunk
		get_tree().current_scene.add_child(cached_chunk)
		Log.debug("WorldManager: Loaded chunk from cache: ", chunk_coord)
		return

	# Check if chunk file exists
	var path = get_chunk_path(chunk_coord)
	if not ResourceLoader.exists(path):
		# Chunk doesn't exist, skip it
		return

	# Start async loading
	var err = ResourceLoader.load_threaded_request(path)
	if err == OK:
		loading_chunks[chunk_coord] = path
		Log.debug("WorldManager: Loading chunk async: ", chunk_coord)
	else:
		Log.debug("WorldManager: Failed to start loading chunk: ", chunk_coord)

func _instantiate_chunk(chunk_coord: Vector2i, scene: PackedScene) -> void:
	"""Instantiate and add a chunk to the scene"""
	var chunk_instance = scene.instantiate()
	var world_pos = get_chunk_world_position(chunk_coord)
	chunk_instance.position = world_pos

	# Set chunk metadata for chunk scenes.
	if chunk_instance is Chunk:
		var chunk_data = ChunkData.new(chunk_coord, get_chunk_path(chunk_coord))
		chunk_data.is_loaded = true
		chunk_instance.chunk_data = chunk_data

	get_tree().current_scene.add_child(chunk_instance)
	loaded_chunks[chunk_coord] = chunk_instance
	Log.debug("WorldManager: Chunk instantiated at ", world_pos, ": ", chunk_coord, " (", chunk_instance.name, ")")

func unload_chunk(chunk_coord: Vector2i) -> void:
	"""Unload a chunk at the given coordinate"""
	if not loaded_chunks.has(chunk_coord):
		return

	var chunk = loaded_chunks[chunk_coord]
	loaded_chunks.erase(chunk_coord)

	# Remove from scene
	chunk.get_parent().remove_child(chunk)

	# Add to cache if there's space
	if chunk_cache.size() < CACHE_SIZE:
		chunk_cache[chunk_coord] = chunk
		Log.debug("WorldManager: Cached chunk: ", chunk_coord)
	else:
		# Free the chunk
		chunk.queue_free()
		Log.debug("WorldManager: Unloaded chunk: ", chunk_coord)

func clear_all_chunks() -> void:
	"""Clear all loaded and cached chunks"""
	for chunk in loaded_chunks.values():
		chunk.queue_free()
	loaded_chunks.clear()

	for chunk in chunk_cache.values():
		chunk.queue_free()
	chunk_cache.clear()

	loading_chunks.clear()
	Log.debug("WorldManager: All chunks cleared")
