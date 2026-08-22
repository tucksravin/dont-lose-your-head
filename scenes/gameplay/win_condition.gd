class_name WinCondition
extends Node
## One named need in a day (DESIGN.md §2.2 "Win conditions").
##
## A pure flag with no logic of its own. Some sensor in the scene (a SpatialGoal,
## a timer, whatever the day uses) calls satisfy(); this emits `satisfied` UP to
## the WinConditionManager. It never touches the head or scene flow — that is the
## DayManager's job. This is the "signal up, call down" leaf.

## Emitted once, the first time this need is met. Carries the key so the manager
## and day can tell body/mind apart without holding a reference to this node.
signal satisfied(key: String)

## Which need this is. Matched against the day's expectations on the HUD (T7).
@export_enum("body", "mind") var key: String = "body"

var is_satisfied: bool = false


## Mark this need met. Idempotent: a body wandering in and out of a goal can't
## re-fire it, so the day-won check stays correct.
func satisfy() -> void:
	if is_satisfied:
		return
	is_satisfied = true
	satisfied.emit(key)


## For restart-in-place (e.g. a fail that doesn't reload the scene).
func reset() -> void:
	is_satisfied = false
