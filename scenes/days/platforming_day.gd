extends DayManager
## Platforming day — only the day-specific actions live here (DESIGN.md §2.1
## "Day 1 (C2)"). Everything generic (release the head, advance, fail → game
## over) is inherited from DayManager.
##
## body need = reach the high goal after three jumps → that drops the bridge.
## mind need = reach the far goal (only reachable once the bridge is down).
## When both are met, the base releases the head and advances.

## The bridge that falls across the gap when the body need is met.
@export var bridge_path: NodePath
## Fall trigger under the gap.
@export var pit_path: NodePath
## The day's sun/timer. Connected by signal name (it has no class_name).
@export var sun_path: NodePath
## Seconds for the bridge to fall into place.
@export var bridge_drop_duration: float = 0.4

@onready var bridge: StaticBody2D = get_node_or_null(bridge_path)
@onready var pit: Area2D = get_node_or_null(pit_path)
@onready var sun: Node2D = get_node_or_null(sun_path)


func _ready() -> void:
	super()  # DayManager wires the WinConditionManager signals.
	# Bridge starts in the air with collision off, or you could stand on nothing.
	bridge.collision_layer = 0
	bridge.collision_mask = 0
	pit.body_entered.connect(_on_pit)
	sun.connect("sunset", _on_sunset)


## Per-need action (called down from the base via the manager). Only the body
## need does anything here; the mind need just counts toward all_satisfied.
func _on_condition_satisfied(key: String) -> void:
	if key == "body":
		_drop_bridge()


func _drop_bridge() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(bridge, "position:y", 0.0, bridge_drop_duration)
	tween.tween_callback(_enable_bridge)


func _enable_bridge() -> void:
	# Layer 1 is the default world layer the body stands on.
	bridge.collision_layer = 1
	bridge.collision_mask = 1


func _on_pit(body: Node2D) -> void:
	if body is CharacterBody2D:
		fail("pit")


func _on_sunset() -> void:
	fail("sunset")
