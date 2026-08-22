extends Node
class_name WinCondition
## One keyed requirement a day needs met before it can end (DESIGN.md §2.2).
##
## This node holds no logic of its own — it is a flag with a name. Something in
## the world decides when it's met and calls satisfy(): a SpatialGoal when the
## body arrives, a food item when it's eaten, whatever the day is about. Keeping
## the flag separate from the thing that trips it means the day's HUD and
## WinConditionManager don't care *how* a need was met.
##
## `class_name WinCondition` registers this as a global type, which is what lets
## WinConditionManager find every one of them with find_children(..., "WinCondition").
## Docs: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#class-name

## Emitted the first time this condition is met. Carries `key` so listeners
## don't need a reference back to this node.
signal satisfied(key: String)

## Which of the day's two needs this is. DESIGN.md §2.1: one body need + one
## mind need per day. @export_enum gives a dropdown in the Inspector instead of
## a free-text field you can typo.
@export_enum("body", "mind") var key: String = "body"

## True once satisfy() has been called. Read it; don't set it.
var is_satisfied: bool = false


## Mark this need as met. Idempotent — a body that wanders in and out of a goal
## area shouldn't fire the day-won check over and over.
func satisfy() -> void:
	if is_satisfied:
		return
	is_satisfied = true
	satisfied.emit(key)


## Clear the flag. Used when a day restarts after the sun runs out (TASKS.md T3)
## if we ever restart in place rather than reloading the scene.
func reset() -> void:
	is_satisfied = false
