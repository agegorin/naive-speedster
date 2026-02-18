extends Resource
class_name TrialDefinition
## TrialDefinition - Configuration for a trial/challenge
##
## Defines all parameters needed to run a trial including objects to spawn,
## completion conditions, and rewards.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var trial_type: TrialTypes.TrialType = TrialTypes.TrialType.CHECKPOINT
@export var spawn_chunk: Vector2i = Vector2i.ZERO
@export var trial_objects: Array[TrialObject] = []
@export var spawn_position: Vector3 = Vector3.ZERO  ## Where trial starts

## Trial-specific parameters
@export_group("Checkpoint Trial")
@export var time_limit: float = 60.0  ## Time limit in seconds
@export var checkpoint_count: int = 5  ## Number of checkpoints

@export_group("Destination Trial")
@export var destination_position: Vector3 = Vector3.ZERO
@export var arrival_radius: float = 5.0

@export_group("Secret Trial")
@export var secret_position: Vector3 = Vector3.ZERO
@export var discovery_radius: float = 3.0

@export_group("Rewards")
@export var reward_part_id: String = ""  ## ID of personality part to unlock

func _init() -> void:
	id = ""
	display_name = "Unnamed Trial"
	trial_type = TrialTypes.TrialType.CHECKPOINT
