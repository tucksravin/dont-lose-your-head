extends Node
class_name StillnessGoal
## The day_panic win: stand still long enough and the need is met.
##
## Mirrors SpatialGoal's shape — a thing in the world that watches for something
## and calls satisfy() on its child WinCondition. SpatialGoal watches *where* the
## body is; this watches whether it is moving at all. The WinCondition itself
## still knows nothing about how it was met (DESIGN.md §2.2).
##
## Finds the body by group rather than a wired path, the same idiom head.gd and
## PanicCounter use, so dropping this into a day needs no per-instance setup.

## Which need standing still satisfies. Set per instance in the day.
@export_enum("body", "mind") var key: String = "mind"
## Seconds of stillness required. Moving resets the clock to zero.
@export var seconds_required: float = 3.0
## Speed below which the body counts as "not moving" (px/s). A hair above zero so
## floor jitter and gravity settling don't read as movement.
@export var still_speed: float = 1.0

## Emitted every frame the player is holding still, with 0.0–1.0 progress, so a
## HUD (TASKS.md T7) can show a "calming down" meter without polling this node.
signal stillness_progress(ratio: float)

@onready var condition: WinCondition = $WinCondition

var _body: CharacterBody2D
var _still_for: float = 0.0


func _ready() -> void:
	condition.key = key
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D
	if _body == null:
		push_warning("StillnessGoal: no node in group 'body' — this goal can never be met.")


func _physics_process(delta: float) -> void:
	if _body == null or condition.is_satisfied:
		return
	if _body.velocity.length() <= still_speed:
		_still_for += delta
		stillness_progress.emit(clampf(_still_for / seconds_required, 0.0, 1.0))
		if _still_for >= seconds_required:
			condition.satisfy()
	elif _still_for > 0.0:
		_still_for = 0.0
		stillness_progress.emit(0.0)


## How close the player is to meeting this need, 0.0–1.0. For a HUD or a day
## script that wants to poll instead of listening.
func progress() -> float:
	return clampf(_still_for / seconds_required, 0.0, 1.0)
