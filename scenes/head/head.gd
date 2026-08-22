class_name Head
extends RigidBody2D
## The head — scripted, not simulated (DESIGN.md §2.1).
##
## In a day scene the head opens **already at its stuck position** and does
## nothing until every WinCondition in the day is satisfied. `WinConditions` then
## reports the win on the `Events` bus, the `Game` autoload calls release(), and
## the head rolls off screen. `left_scene` fires once it is gone, which is what
## tells `Game` it may finally load the next day. That roll *is* the day's outro
## beat — there is no separate outro scene.
##
## Why a frozen RigidBody2D instead of a plain Node2D: keeping the node type
## means real rolling physics is one line away — stop freezing it — if the
## scripted version ever feels lifeless. See the "Reversible" note in
## DESIGN.md §2.1. The "roll" here is deliberately faked: we translate the body
## and spin it, so the exit is pixel-identical every run. T2's acceptance test
## asks for "every run", and §4.3 flags RigidBody2D tuning as a first-timer time
## sink, so real physics stays parked.
##
## `freeze = true` is set in head.tscn rather than here so the head also sits
## still when you preview the scene in the editor. This script only picks *how*
## it is frozen: freeze_mode KINEMATIC (rather than the default STATIC) is the
## mode meant for "I move this body from code" — it still reports collisions and
## can push other bodies, where STATIC expects the body to never move at all.
## Docs: https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html

## Emitted the instant release() is called — the head has started leaving.
signal released
## Emitted once the head is fully off screen. Game listens for this to advance.
signal left_scene

## How fast the head travels once released (px/s).
@export var exit_speed: float = 180.0
## Which way the head leaves. Right by default; a day can point it anywhere.
@export var exit_direction: Vector2 = Vector2.RIGHT
## How fast the head spins as it goes (degrees/s). Set 0 for a plain slide.
@export var spin_speed: float = 360.0
## Pixels past the viewport edge before left_scene fires, so it is fully hidden.
@export var exit_margin: float = 64.0
## Start this head caged — plays the "imprisoned" loop from head_frames.tres
## instead of the plain head. Set it per instance in the day scene; day_panic
## uses it. The cage is art only: nothing about release() changes.
@export var caged: bool = false
## Caged only: how far (px) the sprite shakes at full agitation (set_agitation
## ≥ jitter_full_agitation). 0 = never shakes. Cosmetic — the head's position
## and collision don't move, only the sprite.
@export var jitter_px: float = 1.5
@export var jitter_full_agitation: float = 4.0
## Caged only: sprite tint at 0 panic and at max panic — the head visibly
## darkens toward the palette's ground green as it gets closer to failing the
## day, on top of the jitter and the animation speeding up. Named from
## Colors (scripts/colors.gd) rather than a one-off hex so it stays a palette
## colour. Harmless on an uncaged head.
@export var calm_tint: Color = Color.WHITE
@export var panic_tint: Color = Colors.DARK_GREEN

var _leaving: bool = false
var _agitation: float = 1.0

@onready var _sprite: AnimatedSprite2D = $Visual


func _ready() -> void:
	if caged:
		_sprite.play(&"imprisoned")

	# Groups are Godot's way to find "the one X in the current scene" without a
	# hard node path. The Game autoload can't know where a day author put the
	# head, so it looks it up by group instead.
	# Docs: https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html
	add_to_group("head")
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	# Nothing to do until release() — skip the per-frame callback entirely
	# rather than running an early-return every physics tick.
	set_physics_process(false)
	set_process(caged) # the shake below is caged-only


func _process(_delta: float) -> void:
	# Shake grows with agitation (day_panic drives it off the meter); the
	# random offset is sprite-only so nothing physical moves.
	var amount: float = jitter_px * clampf(_agitation / jitter_full_agitation, 0.0, 1.0)
	if amount < 0.25:
		_sprite.position = Vector2.ZERO
		return
	_sprite.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _physics_process(delta: float) -> void:
	global_position += exit_direction.normalized() * exit_speed * delta
	rotation += deg_to_rad(spin_speed) * delta
	if _is_off_screen():
		set_physics_process(false)
		left_scene.emit()


## How fast the caged head's loop runs. 1.0 is the rate authored in
## head_frames.tres; a day raises it to show the head getting agitated (day_panic
## does this as panic climbs). Harmless on an uncaged head.
func set_agitation(scale: float) -> void:
	_agitation = maxf(scale, 0.0)
	_sprite.speed_scale = _agitation


## How panicked the head is, 0–1 against max_panic. Tints the sprite from
## `calm_tint` toward `panic_tint`. Harmless on an uncaged head.
func set_panic_ratio(ratio: float) -> void:
	_sprite.modulate = calm_tint.lerp(panic_tint, clampf(ratio, 0.0, 1.0))


## Let the head go. Game calls this once every WinCondition is satisfied.
## Safe to call more than once — repeat calls are ignored.
func release() -> void:
	if _leaving:
		return
	_leaving = true
	released.emit()
	set_physics_process(true)


## True once the head has cleared the visible rect by exit_margin.
##
## get_viewport_rect() is screen space, (0,0)→(640,360). Days use a fixed camera
## centred on the screen (DESIGN.md §2.1 "Fixed camera per scene"), so world and
## screen coordinates line up 1-to-1 and this comparison is valid. It would need
## revisiting if a scene ever scrolled.
func _is_off_screen() -> bool:
	var view: Vector2 = get_viewport_rect().size
	return (
		global_position.x > view.x + exit_margin or global_position.x < -exit_margin
		or global_position.y > view.y + exit_margin or global_position.y < -exit_margin
	)
