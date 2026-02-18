extends Control
class_name TrialHUD
## TrialHUD - Displays trial information during active trials
##
## Shows timer, checkpoint progress, and notifications.

@onready var timer_label = $VBoxContainer/TimerLabel
@onready var progress_label = $VBoxContainer/ProgressLabel
@onready var notification_label = $NotificationLabel

var active_trial: Trial = null
var notification_timer: float = 0.0
const NOTIFICATION_DURATION: float = 3.0

func _ready() -> void:
	hide()  # Hidden by default
	TrialManager.trial_started.connect(_on_trial_started)
	TrialManager.trial_completed.connect(_on_trial_completed)

func _process(delta: float) -> void:
	if active_trial:
		_update_display()

		# Check for cancel input
		if Input.is_action_just_pressed("pause"):
			TrialManager.cancel_trial()

	# Update notification timer
	if notification_timer > 0:
		notification_timer -= delta
		if notification_timer <= 0:
			notification_label.hide()

func _on_trial_started(trial: Trial) -> void:
	"""Show HUD when trial starts"""
	active_trial = trial
	show()

	# Connect to trial signals
	trial.checkpoint_passed.connect(_on_checkpoint_passed)
	trial.time_updated.connect(_on_time_updated)

	# Show start notification
	_show_notification("Trial Started: " + trial.definition.display_name)

	Log.debug("TrialHUD: Showing HUD for trial: ", trial.definition.display_name)

func _on_trial_completed(trial_id: String, success: bool) -> void:
	"""Hide HUD when trial completes"""
	if success:
		_show_notification("Trial Completed!")
	else:
		_show_notification("Trial Failed")

	# Hide HUD after a delay
	await get_tree().create_timer(2.0).timeout
	hide()
	active_trial = null

func _on_checkpoint_passed(index: int, total: int) -> void:
	"""Show checkpoint passed notification"""
	_show_notification("Checkpoint %d/%d" % [index + 1, total])

func _on_time_updated(_elapsed: float, _remaining: float) -> void:
	"""Update timer display"""
	# Timer is updated in _update_display
	pass

func _update_display() -> void:
	"""Update all display elements"""
	if not active_trial:
		return

	# Update timer (for checkpoint trials)
	if active_trial.definition.trial_type == TrialTypes.TrialType.CHECKPOINT:
		var remaining = active_trial.get_time_remaining()
		var minutes = int(remaining) / 60
		var seconds = int(remaining) % 60
		timer_label.text = "Time: %02d:%02d" % [minutes, seconds]

		# Warning color when low on time
		if remaining < 10:
			timer_label.add_theme_color_override("font_color", Color.RED)
		else:
			timer_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		timer_label.text = ""

	# Update progress
	if active_trial.definition.trial_type == TrialTypes.TrialType.CHECKPOINT:
		progress_label.text = "Checkpoints: %d/%d" % [
			active_trial.checkpoints_passed,
			active_trial.definition.checkpoint_count
		]
	else:
		progress_label.text = ""

func _show_notification(text: String) -> void:
	"""Show a temporary notification"""
	notification_label.text = text
	notification_label.show()
	notification_timer = NOTIFICATION_DURATION
	Log.debug("TrialHUD: ", text)
