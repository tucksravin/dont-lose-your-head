class_name FloorPlate
extends AnimatedSprite2D
## A floor button, drawn with button.png (Tucker's: off → mid → on).
##
## **You have to land on it.** Walking over one only squashes it to `mid` under
## the body's weight; a hop onto it slams it flat and fires `stomped` (Tucker,
## Sat: "should have to jump on the button to activate, catch body's momentum
## in the animation and rise back up after leaving"). Step off and it rises.
##
## The plate carries the *look and the trigger*; whoever owns it decides what a
## stomp means — the lockdown plates answer a puzzle, the panic button opens the
## cage. Both just connect `stomped`.
##
## Momentum: the body's downward speed at touchdown is remembered while it is
## airborne and scales how fast `press` plays, so a drop from height reads
## harder than a hop in place. It is passed to `stomped` too, if the owner
## wants it.
##
## Why not an Area2D overlap test: the body's `landed` signal (body.gd, the
## air→floor edge) fires inside the body's own `_physics_process`, but an
## Area2D delivers `body_entered` at the END of the physics step — so on a hop
## onto a plate the landing arrives BEFORE the overlap is known, and an
## occupancy-gated check misses it every time (measured: 0 of 4 hops). So this
## asks where the body is instead.

## Emitted when the body lands on this plate. `impact` is its downward speed at
## touchdown (px/s) — ~300 for a plain hop, more from a height.
signal stomped(impact: float)

## While false the plate ignores the body entirely (the lockdown plates are
## dead until the head is seated).
@export var enabled: bool = true
## How far the body's centre may be from the plate's, in x and y, to count as
## being on it. 16 = the plate's own half-width at 2x.
@export var reach_x: float = 16.0
@export var reach_y: float = 24.0
## Downward speed that reads as a normal hop; `press` plays at 1x here.
@export var base_impact: float = 300.0
## Once stomped, stay down for good (the panic button's cage does not re-close).
@export var latch: bool = false

var _body: CharacterBody2D = null
var _fall: float = 0.0
var _down: bool = false
var _latched: bool = false


func _ready() -> void:
	# The body adds itself to the "body" group in its _ready (body.gd), so no
	# node path is needed and this works in any scene.
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D
	if _body != null and _body.has_signal("landed"):
		_body.landed.connect(_on_body_landed)
	_play(&"off")


func _physics_process(_delta: float) -> void:
	if _body == null or not is_instance_valid(_body):
		return
	# Remember the fastest downward speed of this fall; it is the impact.
	if not _body.is_on_floor():
		_fall = maxf(_fall, _body.velocity.y)
	if not enabled or _latched:
		return
	var over: bool = _over_plate()
	if over and _body.is_on_floor():
		if not _down:
			_play(&"mid")  # standing on it, but that is not a press
	elif _down or (animation != &"off" and animation != &"rise"):
		_release()


## True when the body is standing on this plate (centres within reach).
func _over_plate() -> bool:
	var d: Vector2 = _body.global_position - global_position
	return absf(d.x) <= reach_x and absf(d.y) <= reach_y


func _on_body_landed() -> void:
	var impact: float = _fall
	_fall = 0.0
	if not enabled or _latched or _body == null or not _over_plate():
		return
	_down = true
	_latched = latch
	# Momentum: a heavier landing drives the plate down faster.
	speed_scale = clampf(impact / base_impact, 0.6, 2.5)
	_play(&"press")
	stomped.emit(impact)


## Popped back up after the body leaves (or the plate is switched off). The
## rise is a one-shot that ends on the raised frame, so there is nothing to
## await and nothing to race with the body stepping straight back on — an
## earlier version awaited `animation_finished` and then forced `off`, which
## stomped on the `mid` of a body that had already returned.
func _release() -> void:
	_down = false
	speed_scale = 1.0
	if animation == &"off" or animation == &"rise":
		return
	if sprite_frames != null and sprite_frames.has_animation(&"rise"):
		_play(&"rise")
	else:
		_play(&"off")


func _play(anim: StringName) -> void:
	if sprite_frames != null and sprite_frames.has_animation(anim) and animation != anim:
		play(anim)


## Let an owner switch the plate off (and pop it up) — the lockdown setup beat.
func set_live(on: bool) -> void:
	enabled = on
	if not on:
		_latched = false
		_play(&"off")
