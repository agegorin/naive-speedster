extends RefCounted
class_name Log

# Keep debug logs off by default to reduce runtime console noise.
const DEBUG_ENABLED: bool = false

static func debug(
	message: Variant,
	arg1: Variant = null,
	arg2: Variant = null,
	arg3: Variant = null,
	arg4: Variant = null,
	arg5: Variant = null,
	arg6: Variant = null,
	arg7: Variant = null,
	arg8: Variant = null
) -> void:
	if DEBUG_ENABLED:
		print(_compose(message, [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8]))

static func info(
	message: Variant,
	arg1: Variant = null,
	arg2: Variant = null,
	arg3: Variant = null,
	arg4: Variant = null,
	arg5: Variant = null,
	arg6: Variant = null,
	arg7: Variant = null,
	arg8: Variant = null
) -> void:
	print(_compose(message, [arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8]))

static func _compose(
	message: Variant,
	parts: Array[Variant]
) -> String:
	var output := str(message)

	for part in parts:
		if part == null:
			continue
		output += " " + str(part)

	return output
