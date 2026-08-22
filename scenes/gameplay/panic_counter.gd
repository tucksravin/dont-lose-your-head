extends Node
class_name PanicCounter
## day_panic's whole mechanic: the caged head starts panicking, and the day is
## won by getting its panic to **zero**.
##
##   moving          -> panic climbs, and the cage animation speeds up with it
##   stop moving     -> panic holds for `calm_delay`, then falls
##   panic reaches 0 -> the child WinCondition is satisfied (the day's need)
##   panic hits max  -> Events.day_failed, the same escape hatch the sun uses
##
## The hold before it starts falling is what makes it a mechanic rather than a
## timer: stopping does not pay off instantly, so twitchy movement never lets it
## recover, while committing to standing still does.
##
## The number is also the picture — the cage loop's speed is mapped straight off
## the meter, so the player reads their progress from the head, not the label.
##
## Finds the body and the head by group, the same idiom Game uses, so dropping
## this into a day needs no per-instance wiring.

## Panic at the start of the day — the head is already agitated when you arrive.
@export var start_panic: float = 15.0
## Panic value that fails the day.
@export var max_panic: float = 30.0
## Panic added per second while the body is moving, at or beyond
## `proximity_range` from the head.
@export var panic_per_second: float = 6.0
## Distance (px) at which nearness to the head stops mattering. Inside it,
## panic gain ramps up toward `proximity_max_multiplier` as the body closes in
## — being near the caged head is what's upsetting it, not just moving.
@export var proximity_range: float = 150.0
## Panic-gain multiplier applied when the body is right on top of the head.
@export var proximity_max_multiplier: float = 3.0
## Seconds of stillness before panic *starts* coming down.
@export var calm_delay: float = 0.5
## Panic removed per second the moment it starts falling.
@export var calm_per_second: float = 3.0
## Panic removed per second once fully settled, `calm_ramp_time` after it
## starts falling. Ramped in with an ease-in curve rather than a flat rate, so
## committing to standing still pays off increasingly well — a twitch back
## into moving resets the ramp, so only real stillness earns the fast calm.
@export var calm_max_per_second: float = 9.0
## Seconds (after calm_delay) for the calm rate to ramp from calm_per_second
## up to calm_max_per_second.
@export var calm_ramp_time: float = 2.0
## Speed below which the body counts as still (px/s).
@export var still_speed: float = 1.0
## Cage-animation speed at 0 panic and at `start_panic`, as a multiple of the
## rate authored in head_frames.tres. Calm is near-still; the starting value is
## the agitated look the day opens on.
@export var calm_agitation: float = 0.1
@export var frantic_agitation: float = 4.0

## Emitted when the whole number changes — the panic display listens to this.
signal panic_changed(value: int)
## Emitted once panic reaches zero, alongside satisfying the WinCondition.
signal calmed

@onready var condition: WinCondition = $WinCondition

var value: float = 0.0

var _body: CharacterBody2D
var _head: Node
var _still_for: float = 0.0
var _failed: bool = false
var _won: bool = false
var _last_reported: int = -1


func _ready() -> void:
	add_to_group("panic_counter")
	value = start_panic
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D
	_head = get_tree().get_first_node_in_group("head")
	if _body == null:
		push_warning("PanicCounter: no node in group 'body' — panic will never change.")
	_apply()


func _physics_process(delta: float) -> void:
	if _failed or _won or _body == null:
		return

	if _body.velocity.length() > still_speed:
		_still_for = 0.0
		value = minf(value + panic_per_second * _proximity_multiplier() * delta, max_panic)
	else:
		# Hold, then fall. Stopping buys calm only if you keep standing there,
		# and the longer you hold it the faster it falls.
		_still_for += delta
		if _still_for >= calm_delay:
			var t: float = clampf((_still_for - calm_delay) / calm_ramp_time, 0.0, 1.0)
			var rate: float = lerpf(calm_per_second, calm_max_per_second, t * t)
			value = maxf(value - rate * delta, 0.0)

	_apply()

	if value <= 0.0:
		_won = true
		calmed.emit()
		condition.satisfy()
	elif value >= max_panic:
		_failed = true
		# DayManager owns fail presentation (game-over card). Found by group
		# so this node stays free of a scene path.
		var manager: Node = get_tree().get_first_node_in_group("day_manager")
		if manager != null and manager.has_method("fail"):
			manager.call("fail", "panic")
		else:
			Events.day_failed.emit("panic")


## Push the meter out to the label and the head.
func _apply() -> void:
	var shown: int = int(ceilf(value))
	if shown != _last_reported:
		_last_reported = shown
		panic_changed.emit(shown)
	if _head != null:
		if _head.has_method("set_agitation"):
			_head.call("set_agitation", lerpf(calm_agitation, frantic_agitation, ratio()))
		if _head.has_method("set_panic_ratio"):
			_head.call("set_panic_ratio", ratio())


## 0.0–1.0 against the starting value, for a HUD that wants a bar.
func ratio() -> float:
	return clampf(value / max_panic, 0.0, 1.0)


## 1.0 at `proximity_range` or beyond, ramping linearly up to
## `proximity_max_multiplier` as the body closes the distance to the head.
func _proximity_multiplier() -> float:
	var head2d: Node2D = _head as Node2D
	if head2d == null:
		return 1.0
	var dist: float = _body.global_position.distance_to(head2d.global_position)
	var closeness: float = 1.0 - clampf(dist / proximity_range, 0.0, 1.0)
	return lerpf(1.0, proximity_max_multiplier, closeness)
