class_name DayManager
extends Node
## Generic day controller — the "call down" half of the architecture (DESIGN §2.2).
##
## Wiring:  WinCondition --satisfied--> WinConditionManager --condition_satisfied
##          / all_satisfied--> DayManager --calls--> head / game_over / Game.next_day().
##
## This base owns what every day shares: when all needs are met, release the
## head and, once it has left, tell Game to advance the playlist; on a fail,
## show the game-over overlay. Per-day scripts EXTEND this and override
## _on_condition_satisfied() (and optionally _on_all_satisfied()) to add the
## day's own actions — e.g. dropping a bridge. Attach the subclass (or this
## script, for a day with no extra actions) to the "DayManager" node.
##
## Game keeps the playlist (`DAY_SCENES`); this node decides *when* the day
## ends. It does not name a next-scene path.
##
## Docs: https://docs.godotengine.org/en/stable/getting_started/step_by_step/signals.html

## The head has started leaving (all needs met).
signal day_won
## A fail trigger fired (pit, sunset, panic, …).
signal day_failed(reason: String)

## The day's WinConditionManager. Assign in the scene.
@export var conditions_path: NodePath
## The day's head. Released when every need is met.
@export var head_path: NodePath
## Optional game-over overlay, shown on fail().
@export var game_over_path: NodePath

# Resolved from the paths above. get_node keeps the reference explicit and local
# rather than reaching across the tree at call time.
@onready var conditions: WinConditionManager = get_node_or_null(conditions_path)
@onready var head: Head = get_node_or_null(head_path)
@onready var game_over: CanvasLayer = get_node_or_null(game_over_path)

var _ending: bool = false


func _ready() -> void:
	add_to_group("day_manager")
	if conditions != null:
		conditions.condition_satisfied.connect(_on_condition_satisfied)
		conditions.all_satisfied.connect(_on_all_satisfied)
	else:
		push_warning("DayManager has no WinConditionManager assigned.")
	if game_over == null:
		push_warning("DayManager has no game-over overlay assigned.")
	_connect_sun()


## The Sun is found by its `sunset` signal, not a hard path — same duck-type
## as Sfx uses. A won or already-failed day ignores sunset (TASKS.md T3).
func _connect_sun() -> void:
	var root: Node = owner if owner != null else get_parent()
	if root == null:
		return
	for node in root.find_children("*", "Node2D", true, false):
		if node.has_signal("sunset"):
			node.connect("sunset", _on_sunset)
			return
	push_warning("DayManager: no Sun under '%s' — this day has no timer." % root.name)


func _on_sunset() -> void:
	fail("sunset")


## Override per day: react to a single need being met (drop a bridge, open a
## door, …). Base does nothing. `key` is "body" or "mind".
func _on_condition_satisfied(_key: String) -> void:
	pass


## All needs met. Default: send the head off and advance when it has left. Days
## rarely need to override this — override _on_condition_satisfied() instead.
func _on_all_satisfied() -> void:
	if _ending:
		return
	_ending = true
	day_won.emit()
	Events.day_completed.emit()
	if head != null:
		head.left_scene.connect(_advance, CONNECT_ONE_SHOT)
		head.release()
	else:
		_advance()


func _advance() -> void:
	Game.next_day()


## Call this from a fail trigger (pit, sunset, a need node that lost). Shows
## the game-over overlay if one is assigned. No-op once the day has already
## been won or failed. Sensors that don't hold a path to this node can also
## emit Events.day_failed — prefer calling fail() (PanicCounter finds this
## node by the "day_manager" group).
func fail(reason: String = "") -> void:
	if _ending:
		return
	_ending = true
	day_failed.emit(reason)
	Events.day_failed.emit(reason)
	if game_over != null:
		game_over.show_over()
	else:
		# No card in this scene — last-ditch reload so the day is not stuck.
		Game.restart_day()
