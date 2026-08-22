extends Node
class_name PanicCounter
## Panic meter. Moving winds it up; standing still calms it after a hold.
## Hitting max fails the day. `win_on_zero` is the stand-still win
## (`day_panic_still`); the hanging-cage day leaves it off and wins on the
## release button instead.
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
## At scene start, stillness does not decrement for this long. Separate from
## `calm_delay` so a jump mid-day can calm immediately while the open still
## holds. 0 = no opening hold.
@export var open_hold: float = 0.0
## If true, only left/right speed counts as moving. A jump in place (the
## cage day's kiki hop) does not raise panic or reset the still timer —
## `CharacterBody2D.velocity.y` would otherwise look like a sprint.
@export var ignore_vertical: bool = false
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
## Stand-still win: hitting 0 satisfies every WinCondition child. Off on the
## hanging-cage day (the button wins). On in day_panic_still.
@export var win_on_zero: bool = false

## Emitted when the whole number changes — the panic display listens to this.
signal panic_changed(value: int)
## Emitted once panic reaches zero (only if win_on_zero).
signal calmed

@onready var condition: WinCondition = get_node_or_null("WinCondition")

var value: float = 0.0

var _body: CharacterBody2D
var _head: Node
var _still_for: float = 0.0
var _elapsed: float = 0.0
var _failed: bool = false
var _won: bool = false
var _last_reported: int = -1


func _ready() -> void:
	add_to_group("panic_counter")
	value = start_panic
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D
	_head = get_tree().get_first_node_in_group("head")
	_head.call("set_panic_level", 1)
	if _body == null:
		push_warning("PanicCounter: no node in group 'body' — panic will never change.")
	_apply()


func _physics_process(delta: float) -> void:
	if _failed or _won or _body == null:
		return

	_elapsed += delta
	if _is_moving():
		_still_for = 0.0
		value = minf(value + panic_per_second * _proximity_multiplier() * delta, max_panic)
	else:
		# Hold, then fall. Stopping buys calm only if you keep standing there,
		# and the longer you hold it the faster it falls. The opening hold is
		# extra: the first `open_hold` seconds never decrement.
		_still_for += delta
		if _elapsed >= open_hold and _still_for >= calm_delay:
			var t: float = clampf((_still_for - calm_delay) / calm_ramp_time, 0.0, 1.0)
			var rate: float = lerpf(calm_per_second, calm_max_per_second, t * t)
			value = maxf(value - rate * delta, 0.0)

	_apply()

	if value <= 0.0 and win_on_zero:
		_won = true
		calmed.emit()
		if _head != null and _head.has_method("play_calm"):
			_head.call("play_calm")
		_satisfy_needs()
	elif value >= max_panic:
		_failed = true
		# DayManager owns fail presentation (game-over card). Found by group
		# so this node stays free of a scene path.
		var manager: Node = get_tree().get_first_node_in_group("day_manager")
		if manager != null and manager.has_method("fail"):
			manager.call("fail", "panic")
		else:
			Events.day_failed.emit("panic")


## Satisfy every WinCondition child (body + mind on the still day, or a
## single `WinCondition` named that if a scene still uses the old layout).
func _satisfy_needs() -> void:
	for child in get_children():
		if child is WinCondition:
			(child as WinCondition).satisfy()


## Push the meter out to the label and the head.
func _apply() -> void:
	var shown: int = int(ceilf(value))
	if shown != _last_reported:
		_last_reported = shown
		panic_changed.emit(shown)
		if _head != null and _head.has_method("set_panic_level"):
			_head.call("set_panic_level", level())
	if _head != null:
		if _head.has_method("set_agitation"):
			_head.call("set_agitation", lerpf(calm_agitation, frantic_agitation, ratio()))
		if _head.has_method("set_panic_ratio"):
			_head.call("set_panic_ratio", ratio())


## Walking (and optionally jumping) counts as moving.
func _is_moving() -> bool:
	if ignore_vertical:
		return absf(_body.velocity.x) > still_speed
	return _body.velocity.length() > still_speed


## 0.0–1.0 against the starting value, for a HUD that wants a bar.
func ratio() -> float:
	return clampf(value / max_panic, 0.0, 1.0)


## Discrete panic band against max_panic, in thirds: 1 below a third, 2 below
## two thirds, 3 above — the sound (and anything else that wants a coarse
## reading instead of the continuous ratio) picks off this instead of value.
func level() -> int:
	var r: float = ratio()
	if r < 1.0 / 3.0:
		return 1
	elif r < 2.0 / 3.0:
		return 2
	return 3


## 1.0 at `proximity_range` or beyond, ramping linearly up to
## `proximity_max_multiplier` as the body closes the distance to the head.
func _proximity_multiplier() -> float:
	var head2d: Node2D = _head as Node2D
	if head2d == null:
		return 1.0
	var dist: float = _body.global_position.distance_to(head2d.global_position)
	var closeness: float = 1.0 - clampf(dist / proximity_range, 0.0, 1.0)
	return lerpf(1.0, proximity_max_multiplier, closeness)
