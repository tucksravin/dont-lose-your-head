extends Node
## Body "juice" — procedural life on top of the sprite sheet: idle breathing,
## stretch on take-off, squash on landing, a lean into the run. No new pixels
## (the art rule) — everything here is scale/rotation on the existing
## AnimatedSprite2D, driven by the body's velocity and its jumped/landed
## signals. Sits beside body.gd as a child component so the controller stays
## about movement; delete this node and the body is exactly as before.
##
## Pixel-art caveat: the project snaps transforms to whole pixels, so a scale
## of 2.06 on a 38 px sprite is a 1 px pop, not a smooth swell. That IS the
## look (pixel-art breathing is a 1 px bob); amplitudes below are tuned for it.
## Scale pivots at the feet because the sprite is drawn with
## `centered = false, offset = (-16, -32)` — its origin is already the ground.

## The body this decorates and the sprite to deform — assigned in body.tscn.
@export var body: CharacterBody2D
@export var sprite: AnimatedSprite2D

## Breathing: ± this much scale.y over one cycle, only when standing still.
@export var breath_amount: float = 0.06
@export var breath_period: float = 2.2
## Take-off stretch (x, y) and how long it takes to settle back.
@export var stretch: Vector2 = Vector2(1.8, 2.3)
@export var stretch_time: float = 0.16
## Landing squash (x, y) and settle time.
@export var squash: Vector2 = Vector2(2.35, 1.7)
@export var squash_time: float = 0.2
## Lean into the direction of travel (degrees) and how quickly it eases.
@export var lean_degrees: float = 4.0
@export var lean_speed: float = 10.0

var _base_scale: Vector2 = Vector2(2, 2)
var _breath_t: float = 0.0
var _impulse: Tween


func _ready() -> void:
	if body == null or sprite == null:
		push_warning("BodyJuice: assign `body` and `sprite` in the scene — doing nothing.")
		set_process(false)
		return
	_base_scale = sprite.scale
	body.jumped.connect(_on_jumped)
	body.landed.connect(_on_landed)


func _process(delta: float) -> void:
	var moving: bool = absf(body.velocity.x) > 1.0
	var grounded: bool = body.is_on_floor()

	# Lean into the run; ease back upright when stopped or airborne.
	var target_lean: float = 0.0
	if moving and grounded:
		target_lean = deg_to_rad(lean_degrees) * signf(body.velocity.x)
	sprite.rotation = lerp_angle(sprite.rotation, target_lean, clampf(lean_speed * delta, 0.0, 1.0))

	# Breathing only while an impulse (stretch/squash) isn't animating the scale.
	if _impulse != null and _impulse.is_valid():
		return
	if not moving and grounded:
		_breath_t += delta
		var s: float = sin(_breath_t / breath_period * TAU)
		sprite.scale = Vector2(_base_scale.x - breath_amount * 0.5 * s, _base_scale.y + breath_amount * s)
	else:
		_breath_t = 0.0
		sprite.scale = _base_scale


func _on_jumped() -> void:
	_impulse_to(stretch, stretch_time)


func _on_landed() -> void:
	_impulse_to(squash, squash_time)


## Snap to a deformed scale, then ease back to normal with a little overshoot.
func _impulse_to(deformed: Vector2, settle: float) -> void:
	if _impulse != null and _impulse.is_valid():
		_impulse.kill()
	sprite.scale = deformed
	_impulse = create_tween()
	_impulse.tween_property(sprite, "scale", _base_scale, settle)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
