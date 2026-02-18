extends Label
## ChunkDebugDisplay - Shows current chunk and loaded chunks info
##
## Displays debug information about chunk streaming.

@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	# Position in top-left corner
	position = Vector2(10, 10)
	add_theme_font_size_override("font_size", 16)

func _process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			text = "Player not found"
			return

	var chunk_coord = WorldManager.get_chunk_coord(player.global_position)
	var loaded_count = WorldManager.loaded_chunks.size()
	var cached_count = WorldManager.chunk_cache.size()
	var loading_count = WorldManager.loading_chunks.size()

	text = "Chunk: (%d, %d)\nLoaded: %d | Cached: %d | Loading: %d\nPos: %.1f, %.1f, %.1f" % [
		chunk_coord.x, chunk_coord.y,
		loaded_count, cached_count, loading_count,
		player.global_position.x,
		player.global_position.y,
		player.global_position.z
	]
