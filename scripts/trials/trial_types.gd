extends Node
class_name TrialTypes
## TrialTypes - Enum definitions for trial system

enum TrialType {
	CHECKPOINT,  ## Drive through gates in sequence within time limit
	DESTINATION, ## Reach a specific location
	SECRET       ## Find hidden object/location
}

enum TrialStatus {
	NOT_STARTED,
	ACTIVE,
	COMPLETED,
	FAILED
}
