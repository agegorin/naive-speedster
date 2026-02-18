extends Node
## SaveManager - Handles save/load functionality
##
## Manages game progress persistence using JSON format for cross-platform compatibility.

const SAVE_PATH = "user://savegame.save"
const SAVE_VERSION = 1

func _ready() -> void:
	Log.debug("SaveManager initialized")

func save_game() -> void:
	"""Save current game state to disk"""
	# TODO: Implement save functionality
	Log.debug("Save game called (stub)")

func load_game() -> Dictionary:
	"""Load game state from disk"""
	# TODO: Implement load functionality
	Log.debug("Load game called (stub)")
	return {}

func has_save_file() -> bool:
	"""Check if a save file exists"""
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	"""Delete the current save file"""
	if has_save_file():
		var absolute_path = ProjectSettings.globalize_path(SAVE_PATH)
		DirAccess.remove_absolute(absolute_path)
		Log.debug("Save file deleted")
