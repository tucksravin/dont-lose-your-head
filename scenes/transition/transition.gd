extends Node2D
## Transition — the interstitial beat between days: the head rolls down a hill,
## the body runs after it, and at the bottom the head lands in its NEXT
## predicament. That last part is the only thing that changes per day.
##
## HOW TO FORK ONE FOR A NEW DAY (decided Fri 22:50: inherited scenes)
##   1. In Godot: right-click transition.tscn → New Inherited Scene. Save it as
##      scenes/transition/transition_<situation>.tscn. Everything here — hill,
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
## traces the hill (a Tween drives `progress`, so the roll is identical every
## run — DESIGN §2.1 "scripted, not simulated"). Its sprite is rotated by
## distance ÷ radius, which is real rolling without slipping. The body is the
## normal body.tscn with `is_scripted = true`: this script feeds it a velocity
## and calls move_and_slide(), so gravity, the slope and the walk animation all
## come for free from body.gd.
##
## The head here is a plain AnimatedSprite2D on the same head_frames.tres as
## head.tscn — NOT an instance of head.tscn. Tried that first: a frozen
## RigidBody2D under a moving PathFollow2D fights it (the physics-state callback
## writes the body's transform back one tick behind, and the lag accumulates —
## the head ended 128 px short of the path's end). A cutscene prop has no
## business being a physics body anyway.
## Docs: https://docs.godotengine.org/en/stable/classes/class_pathfollow2d.html

## Seconds for the head to roll the sloped part of the path (it accelerates).
@export var roll_slope_time: float = 1.4
## Seconds to coast the flat part and stop (it decelerates).
@export var roll_flat_time: float = 0.8
## Where along the path (0–1) the slope ends and the flat run-out begins.
@export_range(0.0, 1.0) var slope_end_ratio: float = 0.8
## Radius of the head on screen (px) — the spin rate is progress / radius.
@export var head_radius: float = 14.0
## The body starts running this long after the head starts rolling.
@export var body_delay: float = 0.4
## Body run speed (px/s) and where it pulls up (world x) — on the flat, a
## couple of strides behind where the head stops.
@export var body_run_speed: float = 150.0
@export var body_stop_x: float = 470.0
@export var body_gravity: float = 980.0
## The arrival beat waits for the body to catch up (so it is watching when the
## head's situation happens), but never longer than this.
@export var body_catch_up_timeout: float = 2.5
## Pause after the arrival beat before the fade.
@export var hold_after_arrival: float = 0.6
@export var fade_duration: float = 0.4

## Emitted when the body has pulled up at body_stop_x.
signal body_arrived

@onready var follow: PathFollow2D = $HeadPath/Follow
## The rolling head. A sprite, not head.tscn — see the header.
@onready var head: AnimatedSprite2D = $HeadPath/Follow/Head
@onready var body: CharacterBody2D = $Body
@onready var fade: ColorRect = $FadeOverlay/Fade

var _body_running: bool = false
var _body_done: bool = false
var _rolling: bool = true
var _done: bool = false


func _ready() -> void:
	follow.progress_ratio = 0.0
	body.is_scripted = true
	# Downhill at run speed the default 1 px floor snap lets the body skip off
	# the slope; a longer snap keeps its feet on the ground.
	body.floor_snap_length = 8.0
	_run()


func _run() -> void:
	var roll: Tween = create_tween()
	roll.tween_property(follow, "progress_ratio", slope_end_ratio, roll_slope_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	roll.tween_property(follow, "progress_ratio", 1.0, roll_flat_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(body_delay).timeout.connect(func() -> void: _body_running = true)
	await roll.finished
	_rolling = false  # from here the arrival owns the head's rotation
	if not _body_done:
		# Whichever comes first: the body pulls up, or we stop waiting for it.
		var catch_up: SceneTreeTimer = get_tree().create_timer(body_catch_up_timeout)
		var waiting: Array[bool] = [true]
		body_arrived.connect(func() -> void: waiting[0] = false, CONNECT_ONE_SHOT)
		catch_up.timeout.connect(func() -> void: waiting[0] = false)
		while waiting[0]:
			await get_tree().process_frame
	await _play_arrival()
	await get_tree().create_timer(hold_after_arrival).timeout
	var out: Tween = create_tween()
	out.tween_property(fade, "modulate:a", 1.0, fade_duration)
	await out.finished
	_done = true
	Game.next_day()


func _process(_delta: float) -> void:
	# Rolling without slipping: angle = arc length / radius. Clockwise for a
	# rightward roll, which in Godot (y down) is positive rotation. Only while
	# rolling — an arrival may want to set the head upright (the cage does).
	if _rolling:
		head.rotation = follow.progress / head_radius


func _physics_process(delta: float) -> void:
	if _done:
		return
	if not body.is_on_floor():
		body.velocity.y += body_gravity * delta
	var running: bool = _body_running and body.global_position.x < body_stop_x
	body.velocity.x = body_run_speed if running else 0.0
	body.move_and_slide()
	if _body_running and not running and not _body_done:
		_body_done = true
		body_arrived.emit()


## The forkable beat. Called once the head has stopped at the foot of the hill;
## override it in the inherited scene's script and await whatever tweens the
## situation needs. The base does a small settle-bounce and nothing else.
func _play_arrival() -> void:
	var bounce: Tween = create_tween()
	bounce.tween_property(head, "scale", Vector2(2.3, 1.7), 0.08)
	bounce.tween_property(head, "scale", Vector2(2.0, 2.0), 0.16)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await bounce.finished
