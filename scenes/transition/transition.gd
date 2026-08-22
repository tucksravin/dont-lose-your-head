extends Node2D
## Transition — the interstitial beat between days. The head is sitting at the
## top of a slope; the player runs the body after it and has ALMOST caught up
## when the day's situation happens to it (a cage drops on it…) — and that is
## what sends it rolling off down the slope, into its next predicament. The
## head is not running away from the body: it just ends up rolling again.
## The situation is the only thing that changes per day.
##
## HOW TO FORK ONE FOR A NEW DAY (decided Fri 22:50: inherited scenes)
##   1. In Godot: right-click transition.tscn → New Inherited Scene. Save it as
##      scenes/transition/transition_<situation>.tscn. Everything here — slope,
##      path, body, fade — is inherited and greyed out; you only add/override.
##   2. Make scenes/transition/transition_<situation>.gd with
##          extends "res://scenes/transition/transition.gd"
##      and override ONLY `_play_arrival()` (it is awaited — take as long as the
##      beat needs; when it returns, the head rolls). Set that script on the
##      inherited scene's root.
##   3. Add any props the situation needs as new nodes in the inherited scene.
##      Tunables below can be overridden on the inherited root too.
##   4. Put the scene in Game.DAY_SCENES right BEFORE the day it leads into.
##   transition_cage.tscn / .gd is the worked example (the cage drops on the
##   head and knocks it rolling → day_panic). Scene inheritance docs:
##   https://docs.godotengine.org/en/stable/tutorials/scripting/scene_organization.html#inheritance
##
## Why inherited scenes and not one shared scene with a slot: the team chose it
## (journals/tucker.md, Fri 23:18 entry "Overnight run, part 2") — it keeps each
## fork a real scene you can open and tweak visually. The cost is that inherited
## .tscn diffs are opaque, so keep base-scene edits rare and announced.
##
## Mechanics, in Godot terms: the head rides a PathFollow2D along a Path2D that
## runs just above the ground (a Tween drives `progress`, so the roll is
## identical every run — DESIGN §2.1 "scripted, not simulated"). Its sprite is
## rotated by distance along the path × a spin rate, which is rolling without
## slipping rounded to whole turns so it comes to rest upright. The body is the
## normal body.tscn and the PLAYER drives it (decided Sat 08:40: "still control
## the body") — walk, jump, body.gd untouched; the ground is a StaticBody2D
## with a CollisionPolygon2D so move_and_slide() handles the incline. This
## script touches the body twice: it lengthens the floor snap (downhill at run
## speed the default 1 px lets it skip), and once the body has reached the
## stopped head it takes the controls away (`is_scripted`) so it pulls up and
## stands there for the fade.
##
## Timeline (decided Sat 14:xx, Tucker — one slope; "the cage should initiate
## the head's roll; the head isn't running away from the body, it just happens
## to end up rolling again"):
##   the head rests at the start of the path, the body spawns left of it
##   → WAIT until the body is within trigger_distance ("I almost caught up to
##     you!"), or arrival_wait runs out so a dawdler still sees it go
##   → the situation (`_play_arrival`) plays — the cage lands, …
##   → the head ROLLS: roll_time at constant speed (it was knocked, so it leaves
##     at speed) for brake_ratio of the path, then brake_time easing to a stop
##   → the beat ENDS only once the body has actually reached the head (no
##     timeout; the hint label says to go after it) → hold → fade → Game.next_day().
##
## The head here is a plain AnimatedSprite2D on the same head_frames.tres as
## head.tscn — NOT an instance of head.tscn. Tried that first: a frozen
## RigidBody2D under a moving PathFollow2D fights it (the physics-state callback
## writes the body's transform back one tick behind, and the lag accumulates —
## the head ended 128 px short of the path's end). A cutscene prop has no
## business being a physics body anyway.
## Docs: https://docs.godotengine.org/en/stable/classes/class_pathfollow2d.html

## The situation fires once the body is this close in x (px) to the resting
## head. Bigger = it happens earlier; smaller = a closer "almost!". The body
## keeps closing while the situation plays, so the real gap at the moment the
## head leaves is smaller than this (measured: ~30 px with the cage fork).
@export var trigger_distance: float = 100.0
## ...or after this many seconds, whoever is or isn't coming. 0 = don't wait.
@export var arrival_wait: float = 4.0
## Seconds the head rolls at constant speed (brake_ratio of the path)…
@export var roll_time: float = 1.0
## …then brakes to a stop over this many seconds (the rest of the path).
@export var brake_time: float = 0.3
@export_range(0.0, 1.0) var brake_ratio: float = 0.85
## Radius of the head on screen (px) — sets the spin rate (rounded to whole
## turns over the roll, so it stops upright; the cage's bars end vertical).
@export var head_radius: float = 14.0
## Floor snap for the body while it is here (px). Downhill at run speed the
## default 1 px lets it skip off the slope; 8 keeps its feet on the ground.
@export var body_floor_snap: float = 8.0
## The body has "reached" the stopped head once its x is within this many px
## of the head's (or past it). It pulls up there — a couple of strides short.
@export var arrive_distance: float = 40.0
## Pause after the body has arrived, before the fade.
@export var hold_after_arrival: float = 0.6
@export var fade_duration: float = 0.4

## The situation has played and the head is rolling.
signal head_rolled
## Emitted once, when the body reaches the stopped head (see arrive_distance).
signal body_arrived

@onready var path: Path2D = $HeadPath
@onready var follow: PathFollow2D = $HeadPath/Follow
## The rolling head. A sprite, not head.tscn — see the header.
@onready var head: AnimatedSprite2D = $HeadPath/Follow/Head
@onready var body: CharacterBody2D = $Body
@onready var fade: ColorRect = $FadeOverlay/Fade

var _rolling: bool = false
var _head_stopped: bool = false
var _arrived: bool = false
var _done: bool = false
var _head_scale: Vector2 = Vector2(2, 2)
## Radians of head rotation per px of path (whole turns over the whole path).
var _spin: float = 0.0


func _ready() -> void:
	follow.progress = 0.0
	_head_scale = head.scale
	body.floor_snap_length = body_floor_snap
	_run()


func _run() -> void:
	var total: float = path.curve.get_baked_length()
	var turns: int = maxi(1, roundi(total / (TAU * head_radius)))
	_spin = float(turns) * TAU / total
	# "I almost caught up to you": the head sits there until the body is nearly
	# on it (or we tire of waiting).
	await _wait_for_gap(trigger_distance, arrival_wait)
	# The situation — what a fork changes. When it returns, the head goes.
	await _play_arrival()
	_rolling = true
	head_rolled.emit()
	# Knocked loose: off at speed down the slope, braking into the final stop.
	var roll: Tween = create_tween()
	roll.tween_property(follow, "progress", total * brake_ratio, roll_time)\
			.set_trans(Tween.TRANS_LINEAR)
	roll.tween_property(follow, "progress", total, brake_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await roll.finished
	_rolling = false
	_head_stopped = true
	# ...and the beat only ends once the body is actually there.
	await _wait_for_gap(arrive_distance, -1.0)
	await get_tree().create_timer(hold_after_arrival).timeout
	var out: Tween = create_tween()
	out.tween_property(fade, "modulate:a", 1.0, fade_duration)
	await out.finished
	_done = true
	Game.next_day()


## True when the body's x is within `max_gap` of the head's, or past it.
func _gap_ok(max_gap: float) -> bool:
	return body.global_position.x >= head.global_position.x - max_gap


## Returns when _gap_ok(max_gap), or after `timeout` seconds of game time.
## timeout < 0 = wait for the player however long it takes; 0 = don't wait.
func _wait_for_gap(max_gap: float, timeout: float) -> void:
	if timeout == 0.0 or _gap_ok(max_gap):
		return
	# Hold the SceneTree in a local — a scene change (F5/F6/F7, a restart)
	# detaches this node before freeing it, and the next frame would resume
	# this loop on the detached node, where get_tree() is null (an engine ERROR
	# plus a script error — day_chain's "interrupt a transition mid-wait" check
	# exists for exactly this). The tree outlives us: the loop spins one more
	# frame and is dropped with the node.
	var tree: SceneTree = get_tree()
	var expired: Array[bool] = [false]
	if timeout > 0.0:
		tree.create_timer(timeout).timeout.connect(func() -> void: expired[0] = true)
	while not expired[0] and not _gap_ok(max_gap):
		await tree.physics_frame


func _process(_delta: float) -> void:
	# Rolling: angle = distance × spin. Clockwise for a rightward roll, which in
	# Godot (y down) is positive rotation. Only while rolling — before the roll
	# the head sits upright, and a situation may pose it (the cage does).
	if _rolling:
		head.rotation = follow.progress * _spin


func _physics_process(delta: float) -> void:
	if _done:
		return
	if not _arrived:
		# The player is driving. "Reached" = level with the STOPPED head, or past it.
		if _head_stopped and _gap_ok(arrive_distance):
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


## The forkable beat: the situation that befalls the resting head — called once
## the body is nearly on it (or arrival_wait ran out). Override it in the
## inherited scene's script and await whatever tweens the situation needs; the
## moment it returns, the head rolls off down the slope. The base does a small
## impact squash and nothing else (returns after the squash-in; the rebound
## overlaps the start of the roll) — a fork's situation is what explains the
## knock (the cage lands on it).
func _play_arrival() -> void:
	var squash: Tween = create_tween()
	squash.tween_property(head, "scale", _head_scale * Vector2(1.15, 0.85), 0.08)
	squash.tween_property(head, "scale", _head_scale, 0.16)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await squash.step_finished
