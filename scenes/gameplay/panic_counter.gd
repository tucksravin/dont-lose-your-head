extends Node
class_name PanicCounter
## Tracks how "panicked" the caged head is — day_panic's fail condition,
## alongside the sun timer. Moving the body winds panic up; holding still lets
## it fall again. At max_panic the day fails via Events.day_failed, the same
## escape hatch the sun timer uses.
##
## It also drives the head's cage animation: the more panicked, the faster the
## head rattles (Head.set_agitation()). That is the whole read of the day —
## the player learns "when I move, it gets worse" from the picture, not the number.
##
## Finds the body and the head by group rather than wired NodePaths — the same
## way Game finds "the" head — so dropping this into a day needs no setup.

## Panic added per second of movement.
@export var panic_per_second: float = 60.0
## Panic removed per second while the body is still. Set 0 for no recovery —
## then any movement is permanent progress toward failing.
@export var calm_per_second: float = 45.0
## Panic value that fails the day. At the defaults that is ~6.7 s of solid
## movement from calm, and ~9 s to recover from full.
@export var max_panic: float = 400.0
## Speed below which the body counts as still (px/s).
@export var still_speed: float = 1.0
## Cage-animation speed at 0 panic and at max panic, as a multiple of the rate
## authored in head_frames.tres. Calm is deliberately near-still — the eyes
## barely drift until something is actually happening.
@export var calm_agitation: float = 0.1
@export var frantic_agitation: float = 4.0
## Floor applied while the body is moving, so the head reacts the instant you
## move rather than waiting for the meter to climb out of the calm range.
@export var moving_agitation: float = 1.0

## Emitted whenever `value` changes — the panic display listens to this.
signal panic_changed(value: int)

var value: float = 0.0

var _body: CharacterBody2D
var _head: Node
var _failed: bool = false
var _last_reported: int = -1


func _ready() -> void:
	add_to_group("panic_counter")
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D
	_head = get_tree().get_first_node_in_group("head")


func _physics_process(delta: float) -> void:
	if _failed or _body == null:
		return

	var moving: bool = _body.velocity.length() > still_speed
	value = clampf(value + (panic_per_second if moving else -calm_per_second) * delta,
			0.0, max_panic)

	# Report only when the whole number changes: the label redraws ~60x/s otherwise.
	var shown: int = int(value)
	if shown != _last_reported:
		_last_reported = shown
		panic_changed.emit(shown)

	if _head != null and _head.has_method("set_agitation"):
		# Ramp with the meter, but never below moving_agitation while moving —
		# otherwise the first second of movement looks like nothing is wrong.
		var agitation: float = lerpf(calm_agitation, frantic_agitation, value / max_panic)
		if moving:
			agitation = maxf(agitation, moving_agitation)
		_head.call("set_agitation", agitation)

	if value >= max_panic:
		_failed = true
		Events.day_failed.emit("panic")


## 0.0–1.0, for a HUD that wants a bar rather than a number.
func ratio() -> float:
	return value / max_panic
