extends Node2D
## Transition — the interstitial beat between days: the head rolls away down
## one long slope, the player runs the body after it, and where the head stops
## it lands in its NEXT predicament. That last part is the only thing that
## changes per day.
##
## HOW TO FORK ONE FOR A NEW DAY (decided Fri 22:50: inherited scenes)
##   1. In Godot: right-click transition.tscn → New Inherited Scene. Save it as
##      scenes/transition/transition_<situation>.tscn. Everything here — slope,
##      path, body, fade — is inherited and greyed out; you only add/override.
##   2. Make scenes/transition/transition_<situation>.gd with
##          extends "res://scenes/transition/transition.gd"
##      and override ONLY `_play_arrival()` (it is awaited — take as long as the
##      beat needs). Set that script on the inherited scene's root.
##   3. Add any props the arrival needs as new nodes in the inherited scene.
##   4. Put the scene in Game.DAY_SCENES right BEFORE the day it leads into.
##   transition_cage.tscn / .gd is the worked example (the head gets caged →
##   day_panic). Scene inheritance docs:
##   https://docs.godotengine.org/en/stable/tutorials/scripting/scene_organization.html#inheritance
##
## Why inherited scenes and not one shared scene with a slot: the team chose it
## (journals/tucker.md, Fri 22:50) — it keeps each fork a real scene you can open
## and tweak visually. The cost is that inherited .tscn diffs are opaque, so keep
## base-scene edits rare and announced.
##
## Mechanics, in Godot terms: the head rides a PathFollow2D along a Path2D that
## runs just above the slope (a Tween drives `progress_ratio`, so the roll is
## identical every run — DESIGN §2.1 "scripted, not simulated"). Its sprite is
## rotated by distance ÷ radius, which is real rolling without slipping.
## The body is the normal body.tscn and the PLAYER drives it (decided Sat
## 08:40: "still control the body") — walk, jump, body.gd untouched. The slope
## is a StaticBody2D with a CollisionPolygon2D, so move_and_slide() handles the
## incline by itself. This script touches the body twice: it lengthens the
## floor snap (downhill at run speed the default 1 px lets it skip off the
## slope), and once the body has reached the head it takes the controls away
## (`is_scripted`) so it pulls up and stands there for the fade.
##
## Timeline: roll (accelerating) → brake → the head has stopped. The situation
## (`_play_arrival`) plays when the body gets within `arrive_distance` of the
## head — or after `arrival_wait` seconds if the player dawdles, so it never
## looks stuck — but the beat does not END until the body is actually there:
## reach the head → `hold_after_arrival` → fade → Game.next_day(). There is no
## timeout on that last wait; the player has to go and get their head.
##
## The head here is a plain AnimatedSprite2D on the same head_frames.tres as
## head.tscn — NOT an instance of head.tscn. Tried that first: a frozen
## RigidBody2D under a moving PathFollow2D fights it (the physics-state callback
## writes the body's transform back one tick behind, and the lag accumulates —
## the head ended 128 px short of the path's end). A cutscene prop has no
## business being a physics body anyway.
## Docs: https://docs.godotengine.org/en/stable/classes/class_pathfollow2d.html

## Seconds for the head to roll most of the way (it accelerates).
@export var roll_time: float = 1.8
## Seconds to brake to a stop over the last stretch (it decelerates).
@export var brake_time: float = 0.4
## Where along the path (0–1) the braking starts.
@export_range(0.0, 1.0) var brake_ratio: float = 0.85
## Radius of the head on screen (px) — the spin rate is progress / radius.
@export var head_radius: float = 14.0
## Floor snap for the body while it is here (px). Downhill at run speed the
## default 1 px lets it skip off the slope; 8 keeps its feet on the ground.
@export var body_floor_snap: float = 8.0
## The body has "reached" the head once its x is within this many px of the
## head's (or past it). It pulls up there — a couple of strides short.
@export var arrive_distance: float = 40.0
## The situation waits for the body to get close (so the player is watching
## when it happens), but not longer than this after the head has stopped.
@export var arrival_wait: float = 2.5
## Pause after the arrival beat, with the body there, before the fade.
@export var hold_after_arrival: float = 0.6
@export var fade_duration: float = 0.4

## Emitted once, when the body reaches the head (see arrive_distance).
signal body_arrived

@onready var follow: PathFollow2D = $HeadPath/Follow
## The rolling head. A sprite, not head.tscn — see the header.
@onready var head: AnimatedSprite2D = $HeadPath/Follow/Head
@onready var body: CharacterBody2D = $Body
@onready var fade: ColorRect = $FadeOverlay/Fade

var _rolling: bool = true
var _head_stopped: bool = false
var _arrived: bool = false
var _done: bool = false
var _head_scale: Vector2 = Vector2(2, 2)


func _ready() -> void:
	follow.progress_ratio = 0.0
	_head_scale = head.scale
	body.floor_snap_length = body_floor_snap
	_run()


func _run() -> void:
	var roll: Tween = create_tween()
	roll.tween_property(follow, "progress_ratio", brake_ratio, roll_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	roll.tween_property(follow, "progress_ratio", 1.0, brake_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await roll.finished
	_rolling = false  # from here the arrival owns the head's rotation
	_head_stopped = true
	# The situation happens when the body gets close — or when we tire of waiting.
	await _wait_for_body(arrival_wait)
	await _play_arrival()
	# ...but the beat only ends once the body is actually there.
	await _wait_for_body(0.0)
	await get_tree().create_timer(hold_after_arrival).timeout
	var out: Tween = create_tween()
	out.tween_property(fade, "modulate:a", 1.0, fade_duration)
	await out.finished
	_done = true
	Game.next_day()


## Returns when the body has reached the head, or — if timeout > 0 — after that
## many seconds of game time, whichever is first.
func _wait_for_body(timeout: float) -> void:
	if _arrived:
		return
	var waiting: Array[bool] = [true]
	body_arrived.connect(func() -> void: waiting[0] = false, CONNECT_ONE_SHOT)
	if timeout > 0.0:
		get_tree().create_timer(timeout).timeout.connect(func() -> void: waiting[0] = false)
	while waiting[0]:
		await get_tree().process_frame


func _process(_delta: float) -> void:
	# Rolling without slipping: angle = arc length / radius. Clockwise for a
	# rightward roll, which in Godot (y down) is positive rotation. Only while
	# rolling — an arrival may want to set the head upright (the cage does).
	if _rolling:
		head.rotation = follow.progress / head_radius


func _physics_process(delta: float) -> void:
	if _done:
		return
	if not _arrived:
		# The player is driving. "Reached" = level with the stopped head, or past it.
		if _head_stopped and body.global_position.x >= head.global_position.x - arrive_distance:
			_arrived = true
			body.is_scripted = true  # controls off; we settle it from here
			body_arrived.emit()
		return
	# Pulled up: no input, but keep gravity and friction so a mid-jump arrival
	# still lands and the body is standing still for the fade. Numbers come from
	# the body itself so this matches how it moves everywhere else.
	if not body.is_on_floor():
		body.velocity.y += float(body.get("gravity")) * delta
	body.velocity.x = move_toward(body.velocity.x, 0.0, float(body.get("speed")))
	body.move_and_slide()


## The forkable beat. Called once the head has stopped on the slope (and the
## body is close, or arrival_wait ran out); override it in the inherited scene's
## script and await whatever tweens the situation needs. The base does a small
## settle-bounce and nothing else — note nothing visibly STOPS the head here; a
## fork's situation is what explains why it stopped (the cage lands on it).
func _play_arrival() -> void:
	var bounce: Tween = create_tween()
	bounce.tween_property(head, "scale", _head_scale * Vector2(1.15, 0.85), 0.08)
	bounce.tween_property(head, "scale", _head_scale, 0.16)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await bounce.finished
