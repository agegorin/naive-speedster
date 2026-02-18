extends Node3D
class_name Chunk
## Chunk - Base class for world chunks
##
## Represents a loaded chunk in the game world. Contains geometry, props, and trial triggers.

@export var chunk_data: ChunkData

func _ready() -> void:
	if chunk_data:
		Log.debug("Chunk loaded: ", chunk_data.get_chunk_name(), " at ", chunk_data.get_world_position())
