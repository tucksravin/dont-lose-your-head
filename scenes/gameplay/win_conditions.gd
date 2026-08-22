extends Node
class_name WinConditions
## Tracks every WinCondition in the day and announces when they're all met.
##
## Drop one of these anywhere in a day scene. On ready it finds all the
## WinCondition nodes in that scene, listens to each, and when the last one is
## satisfied it emits `Events.day_completed`. It does not know or care what
## happens next — the `Game` autoload owns that (releasing the head, loading the
## next day). This node's whole job is answering "is the day won yet?".
##
## Conditions are found by searching the scene rather than by being children of
## this node, so a day author can put each condition where it belongs spatially
## (a WinCondition under the SpatialGoal it belongs to) instead of collecting
## them all under one parent. Order doesn't matter — needs can be met either way
## round (TASKS.md T4).

## Emitted when the last condition is satisfied. Local mirror of
## `Events.day_completed`, for anything in this scene that wants to react.
signal all_satisfied

var _conditions: Array[WinCondition] = []
var _won: bool = false


func _ready() -> void:
	# `owner` is the root of the scene this node was saved into, so this keeps
	# working if a day is ever instanced inside another scene rather than loaded
	# as the current scene.
	var root: Node = owner if owner != null else get_parent()
	# find_children(pattern, type, recursive, owned): owned = false is the
	# important argument — a WinCondition living inside an instanced sub-scene
	# like spatial_goal.tscn is owned by *that* scene, not by the day, so
	# owned = true would miss it.
	# Docs: https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-find-children
	for node in root.find_children("*", "WinCondition", true, false):
		var condition: WinCondition = node as WinCondition
		_conditions.append(condition)
		condition.satisfied.connect(_on_condition_satisfied)

	if _conditions.is_empty():
		push_warning("WinConditions: no WinCondition nodes under '%s' — this day can never be won." % root.name)


## Every condition currently tracked. The HUD (TASKS.md T7) uses this to build
## one indicator per need at startup.
func get_conditions() -> Array[WinCondition]:
	return _conditions.duplicate()


func _on_condition_satisfied(key: String) -> void:
	Events.condition_satisfied.emit(key)
	if _won:
		return
	for condition in _conditions:
		if not condition.is_satisfied:
			return
	_won = true
	all_satisfied.emit()
	Events.day_completed.emit()
