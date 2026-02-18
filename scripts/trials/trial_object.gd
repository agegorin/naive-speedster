extends Resource
class_name TrialObject
## TrialObject - Defines an object to spawn during a trial
##
## Objects include gates, obstacles, ramps, walls, etc.

@export var scene_path: String = ""
@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO
@export var scale: Vector3 = Vector3.ONE

func _init(path: String = "", pos: Vector3 = Vector3.ZERO, rot: Vector3 = Vector3.ZERO) -> void:
	scene_path = path
	position = pos
	rotation = rot
