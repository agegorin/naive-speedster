extends Node
## GameManager - General game state and flow management
##
## Handles overall game state, scene transitions, and coordination between other managers.

enum GameState {
	MAIN_MENU,
	LOADING,
	IN_GAME,
	PAUSED,
	CUSTOMIZATION
}

var current_state: GameState = GameState.MAIN_MENU

func _ready() -> void:
	print("GameManager initialized")

func change_state(new_state: GameState) -> void:
	"""Change the current game state"""
	current_state = new_state
	print("Game state changed to: ", GameState.keys()[new_state])

func pause_game() -> void:
	"""Pause the game"""
	get_tree().paused = true
	change_state(GameState.PAUSED)

func resume_game() -> void:
	"""Resume the game"""
	get_tree().paused = false
	change_state(GameState.IN_GAME)
