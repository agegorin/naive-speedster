extends Resource
class_name ChunkData
## ChunkData - Metadata and configuration for world chunks
##
## Stores information about a chunk including its coordinate, scene path, and state.

@export var chunk_coord: Vector2i = Vector2i.ZERO
@export var scene_path: String = ""
@export var is_loaded: bool = false
@export var has_trials: bool = false
@export var trial_ids: Array[String] = []

func _init(coord: Vector2i = Vector2i.ZERO, path: String = "") -> void:
	chunk_coord = coord
	scene_path = path

func get_chunk_name() -> String:
	"""Generate chunk name from coordinates"""
	return "chunk_%d_%d" % [chunk_coord.x, chunk_coord.y]

func get_world_position() -> Vector3:
	"""Get the world position of chunk's center"""
	const CHUNK_SIZE = 100.0
	return Vector3(
		chunk_coord.x * CHUNK_SIZE,
		0,
		chunk_coord.y * CHUNK_SIZE
	)
