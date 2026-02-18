extends Node
## PlayerInventory - Manages player's collected parts
##
## Tracks unlocked parts and provides access to owned parts for customization.

var unlocked_parts: Array[String] = []
var equipped_parts: Dictionary = {
	"engine": null,
	"wheels": null,
	"body": null
}

func _ready() -> void:
	Log.debug("PlayerInventory initialized")
	_initialize_default_parts()

func _initialize_default_parts() -> void:
	"""Give player starting parts"""
	# TODO: Add default starting parts when part system is implemented
	pass

func add_part(part_id: String) -> void:
	"""Unlock a new part"""
	if part_id not in unlocked_parts:
		unlocked_parts.append(part_id)
		Log.debug("Part unlocked: ", part_id)

func has_part(part_id: String) -> bool:
	"""Check if player owns a specific part"""
	return part_id in unlocked_parts

func equip_part(part_id: String, slot: String) -> void:
	"""Equip a part to a specific slot"""
	if has_part(part_id) and slot in equipped_parts:
		equipped_parts[slot] = part_id
		Log.debug("Part equipped: ", part_id, " to slot: ", slot)
