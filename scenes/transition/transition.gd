extends Node2D
## Transition — the interstitial beat between days: the head rolls away down a
## slope, the player runs the body after it, the head pauses on a shelf just
## long enough for an "I almost caught up to you!" — then rolls again, down a
## second slope, and where it finally stops it lands in its NEXT predicament.
## That last part is the only thing that changes per day.
##
## HOW TO FORK ONE FOR A NEW DAY (decided Fri 22:50: inherited scenes)
##   1. In Godot: right-click transition.tscn → New Inherited Scene. Save it as
##      scenes/transition/transition_<situation>.tscn. Everything here — slopes,
##      path, body, fade — is inherited and greyed out; you only add/override.
##   2. Make scenes/transition/transition_<situation>.gd with
##          extends "res://scenes/transition/transition.gd"
##      and override ONLY `_play_arrival()` (it is awaited — take as long as the
##      beat needs). Set that script on the inherited scene's root.
##   3. Add any props the arrival needs as new nodes in the inherited scene.
##      Tunables below can be overridden on the inherited root too (the cage
##      fork sets arrival_wait = 0 so the cage lands before the body arrives).
##   4. Put the scene in Game.DAY_SCENES right BEFORE the day it leads into.
##   transition_cage.tscn / .gd is the worked example (the head gets caged →
##   day_panic). Scene inheritance docs:
##   https://docs.godotengine.org/en/stable/tutorials/scripting/scene_organization.html#inheritance
##
## Why inherited scenes and not one shared scene with a slot: the team chose it
## (journals/tucker.md, Fri 23:18 entry "Overnight run, part 2") — it keeps each
## fork a real scene you can open and tweak visually. The cost is that inherited
## .tscn diffs are opaque, so keep base-scene edits rare and announced.
##
## Mechanics, in Godot terms: the head rides a PathFollow2D along a Path2D that
## runs just above the ground (slope 1 → shelf → slope 2; a Tween drives
## `progress`, so the roll is identical every run — DESIGN §2.1 "scripted, not
## simulated"). Its sprite is rotated by distance ÷ radius, which is real rolling
## without slipping. The body is the normal body.tscn and the PLAYER drives it
## (decided Sat 08:40: "still control the body") — walk, jump, body.gd untouched;
## the ground is a StaticBody2D with a CollisionPolygon2D so move_and_slide()
## handles the inclines. This script touches the body twice: it lengthens the
## floor snap (downhill at run speed the default 1 px lets it skip), and once
## the body has reached the head it takes the controls away (`is_scripted`) so
## it pulls up and stands there for the fade.
##
## Timeline (decided Sat evening, Tucker — "an 'I almost caught up to you'
## moment, then the head gets rolling again down another slope"):
##   roll 1 (roll1_time) down slope 1, coming to rest on the shelf at pause_x
##   → WAIT until the body is within wake_distance (or wake_wait runs out, so
##     a dawdler still sees it go) → `head_woke`
##   → roll 2 (roll2_time accelerating + brake_time) down slope 2 to the end of
##     the path → the head has stopped
##   → the situation (`_play_arrival`) plays when the body is within
##     arrive_distance, or after arrival_wait (0 = immediately, before the body
##     can get there — what the cage fork wants)
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

## Seconds for roll 1: down the first slope onto the shelf (ease in, ease out —
## it starts from rest and rolls to rest).
@export var roll1_time: float = 1.1
## World x where the head comes to rest on the shelf between the slopes.
@export var pause_x: float = 290.0
## The head rolls again once the body is this close in x (px). Bigger = it
## leaves earlier; smaller = a closer "almost".
@export var wake_distance: float = 72.0
## ...or after this many seconds on the shelf, whoever is or isn't coming.
@export var wake_wait: float = 4.0
## Seconds for roll 2: down the second slope, accelerating to brake_ratio of
## the remaining path, then braking for brake_time.
@export var roll2_time: float = 1.0
@export var brake_time: float = 0.3
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
## 0 = don't wait: it happens the moment the head stops (the cage fork).
@export var arrival_wait: float = 2.5
## Pause after the arrival beat, with the body there, before the fade.
@export var hold_after_arrival: float = 0.6
@export var fade_duration: float = 0.4

## The head has left the shelf (the "almost!" moment is over).
signal head_woke
## Emitted once, when the body reaches the stopped head (see arrive_distance).
signal body_arrived

@onready var path: Path2D = $HeadPath
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
	follow.progress = 0.0
	_head_scale = head.scale
	body.floor_snap_length = body_floor_snap
	_run()


func _run() -> void:
	var total: float = path.curve.get_baked_length()
	var pause: float = _progress_at_x(pause_x)
	# Roll 1: down the first slope, coming to rest on the shelf.
	var roll1: Tween = create_tween()
	roll1.tween_property(follow, "progress", pause, roll1_time)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await roll1.finished
	_rolling = false
	# "I almost caught up to you": it sits there until the body is nearly on it.
	await _wait_for_gap(wake_distance, wake_wait)
	head_woke.emit()
	_rolling = true
	# Roll 2: away again, down the second slope, braking into the final stop.
	var brake_at: float = pause + (total - pause) * brake_ratio
	var roll2: Tween = create_tween()
	roll2.tween_property(follow, "progress", brake_at, roll2_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	roll2.tween_property(follow, "progress", total, brake_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await roll2.finished
	_rolling = false  # from here the arrival owns the head's rotation
	_head_stopped = true
	# The situation happens when the body gets close — or at once (arrival_wait 0),
	# or when we tire of waiting.
	if arrival_wait > 0.0:
		await _wait_for_gap(arrive_distance, arrival_wait)
	await _play_arrival()
	# ...but the beat only ends once the body is actually there.
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


## Path offset (px along the curve) of the first baked point at or past world x.
func _progress_at_x(x: float) -> float:
	var pts: PackedVector2Array = path.curve.get_baked_points()
	var total: float = path.curve.get_baked_length()
	for i in pts.size():
		if path.to_global(pts[i]).x >= x:
			return total * float(i) / float(maxi(pts.size() - 1, 1))
	return total


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


## The forkable beat. Called once the head has finally stopped (and the body
## is close, or arrival_wait ran out / was 0); override it in the inherited
## scene's script and await whatever tweens the situation needs. The base does
## a small settle-bounce and nothing else — note nothing visibly STOPS the head
## on the second slope; a fork's situation is what explains why it stopped
## (the cage lands on it).
func _play_arrival() -> void:
	var bounce: Tween = create_tween()
	bounce.tween_property(head, "scale", _head_scale * Vector2(1.15, 0.85), 0.08)
	bounce.tween_property(head, "scale", _head_scale, 0.16)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await bounce.finished
