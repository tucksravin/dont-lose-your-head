class_name DayManager
extends Node
## Generic day controller — the "call down" half of the architecture.
##
## Wiring:  WinCondition --satisfied--> WinConditionManager --condition_satisfied
##          / all_satisfied--> DayManager --calls--> head / game_over / scene flow.
##
## This base owns the parts every day shares: when all needs are met, release the
## head and, once it has left, advance to the next scene; on a fail, show the
## game-over overlay. Per-day scripts EXTEND this and override
## _on_condition_satisfied() (and optionally _on_all_satisfied()) to add the
## day's own actions — e.g. dropping a bridge. Attach the subclass to the
## "DayManager" node in the day scene.

## The head has started leaving (all needs met).
signal day_won
## A fail trigger fired (pit, sunset, …).
signal day_failed(reason: String)

## Scene to load once the head is gone. Empty = stay put (lets a future Game
## day-list own flow instead).
@export_file("*.tscn") var next_scene: String = "res://scenes/reunion/reunion.tscn"
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
	if conditions != null:
		conditions.condition_satisfied.connect(_on_condition_satisfied)
		conditions.all_satisfied.connect(_on_all_satisfied)
	else:
		push_warning("DayManager has no WinConditionManager assigned.")


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
	if head != null:
		head.left_scene.connect(_advance, CONNECT_ONE_SHOT)
		head.release()
	else:
		_advance()


func _advance() -> void:
	if not next_scene.is_empty():
		Game.change_scene(next_scene)


## Call this from a fail trigger (pit fall, sunset). Shows the game-over overlay
## if one is assigned. No-op once the day has already been won.
func fail(reason: String = "") -> void:
	if _ending:
		return
	day_failed.emit(reason)
	if game_over != null:
		game_over.show_over()
