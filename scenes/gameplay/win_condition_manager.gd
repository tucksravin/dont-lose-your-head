class_name WinConditionManager
extends Node
## Collects a day's WinConditions and reports upward (the mediator).
##
## Auto-discovers every WinCondition under `search_root` (or the scene root) at
## _ready, and also exposes register() so a day can add one that spawns partway
## through the run. Signal up: `condition_satisfied(key)` as each need is met,
## and `all_satisfied` once every registered condition is satisfied.
##
## It knows nothing about the head, the bridge, or scene flow — the DayManager
## listens to these and decides what to do (call down).

## A single need was just met. The DayManager uses this for per-need actions.
signal condition_satisfied(key: String)
## Every registered need is met. The DayManager uses this to end the day.
signal all_satisfied

## Where to scan for WinConditions. Left empty, it uses the scene root (`owner`),
## so a condition can sit anywhere in the day — next to whatever trips it.
@export var search_root: Node

var _conditions: Array[WinCondition] = []
var _satisfied: Array[WinCondition] = []
var _completed: bool = false


func _ready() -> void:
	var root: Node = search_root
	if root == null:
		root = owner if owner != null else self
	for condition in root.find_children("*", "WinCondition", true, false):
		register(condition)
	if _conditions.is_empty():
		push_warning("WinConditionManager: no WinConditions found under %s" % root.name)


## Track a WinCondition. Called once per auto-discovered condition, and can be
## called by a day that spawns a new goal mid-run. Safe to call twice on the
## same node. A condition that's already satisfied when registered counts at once.
func register(condition: WinCondition) -> void:
	if _conditions.has(condition):
		return
	_conditions.append(condition)
	# bind() appends the node, so the handler gets (key, condition) and can tell
	# which one fired without WinCondition needing to know about this manager.
	condition.satisfied.connect(_on_satisfied.bind(condition))
	if condition.is_satisfied:
		_on_satisfied(condition.key, condition)


func _on_satisfied(key: String, condition: WinCondition) -> void:
	if _satisfied.has(condition):
		return
	_satisfied.append(condition)
	condition_satisfied.emit(key)
	_check_all()


func _check_all() -> void:
	if _completed or _conditions.is_empty():
		return
	if _satisfied.size() >= _conditions.size():
		_completed = true
		all_satisfied.emit()
