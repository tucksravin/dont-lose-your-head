class_name Head
extends RigidBody2D
## The head — scripted, not simulated (DESIGN.md §2.1).
##
## In a day scene the head opens **already at its stuck position** and does
## nothing until every WinCondition in the day is satisfied. DayManager then
## calls release(), and the head rolls off screen. `left_scene` fires once it
## is gone, which is what tells DayManager to call `Game.next_day()`. That
## roll *is* the day's outro beat — there is no separate outro scene.
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
## `attach(carrier)` / `detach()` let a day have the head follow a node
## (lockdown: the body) without reparenting — same idea as `release()`: the day
## decides *when*, this script owns *how it moves*.
## Docs: https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html

## Emitted the instant release() is called — the head has started leaving.
signal released
## Emitted once the head is fully off screen. DayManager listens for this to advance.
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
## How far (px) the sprite shakes at full agitation (set_agitation
## ≥ jitter_full_agitation). 0 = never shakes. Cosmetic — the head's position
## and collision don't move, only the sprite. Caged heads start processing
## in `_ready`; a loose head starts when something calls `set_agitation`
## (PanicCounter, the intro swarm).
@export var jitter_px: float = 1.5
@export var jitter_full_agitation: float = 4.0
## Sprite tint at 0 panic and at max panic — the head visibly darkens toward
## the palette's ground green as it gets closer to failing the day, on top of
## the jitter. Named from Colors (scripts/colors.gd) rather than a one-off hex
## so it stays a palette colour.
@export var calm_tint: Color = Color.WHITE
@export var panic_tint: Color = Colors.DARK_GREEN
## Caged only: the discrete panic-level sound (index 0 = level 1 .. index 2 =
## level 3) — PanicCounter picks the level off its own thirds-of-max_panic
## bands (PanicCounter.level()) and calls set_panic_level() with it; this
## script only knows how to play whichever index that is. Local to the head,
## not a global sfx script — same reasoning as Body's jump/landing sounds.
## Defaults preloaded here (not wired per-instance in day_panic.tscn) so a
## caged head works out of the box, same as calm_tint/panic_tint above.
@export var panic_sounds: Array[AudioStream] = [
	preload("res://assets/audio/sfx/panic/panic_level_1_1.wav"),
	preload("res://assets/audio/sfx/panic/panic_level_2_1.wav"),
	preload("res://assets/audio/sfx/panic/panic_level_3_1.wav"),
]
## Caged only: the one-shot for PanicCounter's `calmed` moment (panic hit 0
## and the day won that way — `win_on_zero` days only). Its own player
## (`_calm_sound`, not `_panic_sound`) so it can be mixed independently —
## volume_db on CalmSound in the scene, no code change needed to retune it.
@export var calm_sound: AudioStream = preload("res://assets/audio/sfx/calm/calm_1.wav")

var _leaving: bool = false
var _agitation: float = 1.0
var _carrier: Node2D = null
var _carry_offset: Vector2 = Vector2(12.0, -40.0)
var panic_level = -1

@onready var _sprite: AnimatedSprite2D = $Visual
@onready var _hitbox: CollisionShape2D = $CollisionShape2D
@onready var _panic_sound: AudioStreamPlayer = $PanicSound
@onready var _calm_sound: AudioStreamPlayer = $CalmSound


func _ready() -> void:
	# Groups are Godot's way to find "the one X in the current scene" without a
	# hard node path. The Game autoload can't know where a day author put the
	# head, so it looks it up by group instead.
	# Docs: https://docs.godotengine.org/en/stable/tutorials/scripting/groups.html
	add_to_group("head")
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	# Nothing to do until attach() or release() — skip the per-frame callback
	# rather than running an early-return every physics tick.
	set_physics_process(false)
	set_process(caged) # shake; a loose head turns this on in set_agitation()
	refresh_face()


func _process(_delta: float) -> void:
	# Shake grows with agitation (day_panic drives it off the meter); the
	# random offset is sprite-only so nothing physical moves.
	var amount: float = jitter_px * clampf(_agitation / jitter_full_agitation, 0.0, 1.0)
	if amount < 0.25:
		_sprite.position = Vector2.ZERO
		return
	_sprite.position = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))


func _physics_process(delta: float) -> void:
	if _carrier != null:
		_follow_carrier()
		return
	global_position += exit_direction.normalized() * exit_speed * delta
	rotation += deg_to_rad(spin_speed) * delta
	if _is_off_screen():
		set_physics_process(false)
		left_scene.emit()


## Follow `carrier` each physics tick (offset.x flips with the carrier's
## `Visual.flip_h` if it has one). Collision off so we don't shove. No-op once
## `release()` has started.
func attach(carrier: Node2D, offset: Vector2 = Vector2(12.0, -40.0)) -> void:
	if _leaving or carrier == null:
		return
	_carrier = carrier
	_carry_offset = offset
	set_solid(false)
	set_physics_process(true)
	_follow_carrier()


## Stop following. Collision back on. Safe to call when not attached.
func detach() -> void:
	_carrier = null
	set_solid(true)
	if not _leaving:
		set_physics_process(false)


## Deferred: release() (and attach()/detach()) can run from inside a
## WinCondition's `satisfied` signal, which fires during the physics engine's
## query flush — toggling a CollisionShape2D's `disabled` state synchronously
## there throws "Can't change this state while flushing queries." Same fix as
## the pickup nodes' `monitoring` toggles (glasses.gd, answer_pad.gd).
func set_solid(solid: bool) -> void:
	if _hitbox != null:
		# Deferred: release() reaches here from inside a physics callback (a
		# SpatialGoal's body_entered → win → Game → release → detach), and
		# flipping a shape's `disabled` while the physics server is flushing
		# queries is an engine ERROR ("Can't change this state while flushing
		# queries") — it turned the smoke suite red on main. set_deferred applies
		# it at the end of the frame, which is one frame later and harmless here.
		_hitbox.set_deferred("disabled", not solid)


## How fast the face loop runs, and how hard the sprite shakes. 1.0 is the
## rate authored in head_frames.tres; PanicCounter lerps this from
## calm_agitation → frantic_agitation as the meter fills. Turns `_process`
## on so a loose head (tree, intro) jitters the same way a caged one does.
func set_agitation(scale: float) -> void:
	_agitation = maxf(scale, 0.0)
	_sprite.speed_scale = _agitation
	set_process(true)


## How panicked the head is, 0–1 against max_panic. Tints the sprite from
## `calm_tint` toward `panic_tint`. Harmless on an uncaged head.
func set_panic_ratio(ratio: float) -> void:
	_sprite.modulate = calm_tint.lerp(panic_tint, clampf(ratio, 0.0, 1.0))


## Play the level-`level` panic sound (1..3 — PanicCounter's discrete thirds
## band, not a continuous value). Retriggers on every call, same as a
## heartbeat thump restarting itself; PanicCounter only calls this when the
## panic *label's* integer value changes, so it can't spam every physics
## frame. No-op if `level` is out of range or panic_sounds isn't wired up
## with all 3 entries. Harmless on an uncaged head.
func set_panic_level(level: int) -> void:
	var index: int = level - 1
	if index < 0 or index >= panic_sounds.size():
		return
	if index == panic_level:
		return
	panic_level = index
	_panic_sound.stream = panic_sounds[index]
	_panic_sound.play()


## Play the "calmed" cue once — PanicCounter calls this from its own `calmed`
## signal. Harmless on an uncaged head; no-op if calm_sound isn't assigned.
func play_calm() -> void:
	_panic_sound.stop()
	if calm_sound == null:
		return
	_calm_sound.stream = calm_sound
	_calm_sound.play()


## Let the head go. Game calls this once every WinCondition is satisfied.
## Safe to call more than once — repeat calls are ignored.
func release() -> void:
	if _leaving:
		return
	_leaving = true
	detach()
	if not caged:
		_play_face(&"loose", &"glasses")
	released.emit()
	set_physics_process(true)


## Face left (−1), right (+1), or the plain front (0). Plays look_left /
## look_right (or the glasses variants when Game.wearing_glasses). No-op if
## caged or already rolling — panic keeps the imprisoned loop.
func look(dir: int) -> void:
	if _leaving or caged or _sprite == null:
		return
	if dir < 0:
		_play_face(&"look_left", &"glasses_look_left")
	elif dir > 0:
		_play_face(&"look_right", &"glasses_look_right")
	else:
		_play_face(&"loose", &"glasses")


## Re-read Game.wearing_glasses and play the matching idle / cage loop.
## Velma calls this after forcing the flag off, and again when they're handed over.
func refresh_face() -> void:
	if caged:
		_play_face(&"imprisoned", &"imprisoned_glasses")
	else:
		_play_face(&"loose", &"glasses")


func set_wearing_glasses(on: bool) -> void:
	Game.wearing_glasses = on
	refresh_face()


## Pick the glasses animation when Game.wearing_glasses, else the plain one.
func _play_face(plain: StringName, glasses: StringName) -> void:
	if _sprite == null:
		return
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null:
		return
	if Game.wearing_glasses and frames.has_animation(glasses):
		_sprite.play(glasses)
	elif frames.has_animation(plain):
		_sprite.play(plain)


func _follow_carrier() -> void:
	if _carrier == null or not is_instance_valid(_carrier):
		detach()
		return
	var offset: Vector2 = _carry_offset
	var sprite: AnimatedSprite2D = _carrier.get_node_or_null("Visual") as AnimatedSprite2D
	if sprite != null and sprite.flip_h:
		offset.x = -offset.x
	global_position = _carrier.global_position + offset


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
