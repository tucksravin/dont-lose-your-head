extends "res://scenes/transition/transition.gd"
## Transition fork: the head rolls the whole hill wearing glasses; they fly
## off mid-roll; the skull never parks — it keeps going off the right into
## Velma. Overrides `_run()` (not just `_play_arrival()`) because the base
## beat is "stop, then the situation". This beat has no stop.
##
## Reparent after the PathFollow2D ends: the head is a child of the follower,
## so a position tween on it would fight the path. `reparent` keeps the
## sprite, drops the path, and lets a Tween carry it off screen.
## Docs: https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-reparent

## Progress along the path (0–1) when the glasses leave the skull.
@export_range(0.0, 1.0) var glasses_fly_at: float = 0.42
## Upward kick (px/s) added to the head's roll velocity. The glasses keep
## the downhill speed and peel up while the skull stays on the path.
@export var glasses_up_kick: float = 280.0
## Gravity on the glasses after they leave (px/s², +Y is down).
@export var glasses_gravity: float = 520.0
## How long the projectile is simulated.
@export var glasses_fly_time: float = 1.1
@export var glasses_spin: float = 8.0
## After the path ends, keep rolling off the right (seconds).
@export var exit_time: float = 0.65
## (720, 264) is 16 px above the ground there — the hill's flat shelf moved to
## the FAR side on Sat (500,280)→(740,280), so the skull now rolls off along
## level ground instead of still descending.
@export var exit_end: Vector2 = Vector2(720.0, 264.0)
@export var exit_spin: float = 3.5

@onready var lost_glasses: Sprite2D = $LostGlasses

var _glasses_flew: bool = false
var _head_last_pos: Vector2 = Vector2.ZERO
var _head_vel: Vector2 = Vector2.ZERO
var _glasses_start: Vector2 = Vector2.ZERO
var _glasses_vel: Vector2 = Vector2.ZERO


## Full beat. Do not call super — the new base parks until the body is close,
## then rolls and stops. This beat never parks.
func _run() -> void:
	# Same spin setup as the base so `_process` can rotate the skull.
	var total: float = path.curve.get_baked_length()
	var turns: int = maxi(1, roundi(total / (TAU * head_radius)))
	_spin = float(turns) * TAU / total
	_head_last_pos = head.global_position
	_head_vel = Vector2.ZERO
	_rolling = true
	var roll: Tween = create_tween()
	roll.tween_property(follow, "progress", total, roll_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await roll.finished
	_rolling = false
	var pos: Vector2 = head.global_position
	var rot: float = head.rotation
	head.reparent(self)
	head.global_position = pos
	head.rotation = rot
	var leave: Tween = create_tween()
	leave.set_parallel(true)
	leave.tween_property(head, "global_position", exit_end, exit_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	leave.tween_property(head, "rotation", rot + exit_spin, exit_time)
	await leave.finished
	var out: Tween = create_tween()
	out.tween_property(fade, "modulate:a", 1.0, fade_duration)
	await out.finished
	_done = true
	Game.next_day()


func _process(delta: float) -> void:
	super._process(delta)
	if _rolling and delta > 0.0:
		var now: Vector2 = head.global_position
		var sample: Vector2 = (now - _head_last_pos) / delta
		if sample.length() > 8.0:
			_head_vel = sample
		_head_last_pos = now
	if _glasses_flew or not _rolling:
		return
	if follow.progress_ratio >= glasses_fly_at:
		_fly_glasses()


func _fly_glasses() -> void:
	_glasses_flew = true
	Game.wearing_glasses = false
	if head.sprite_frames != null and head.sprite_frames.has_animation(&"loose"):
		head.play(&"loose")
	if lost_glasses == null:
		return
	lost_glasses.global_position = head.global_position
	lost_glasses.rotation = 0.0
	lost_glasses.visible = true
	_glasses_start = head.global_position
	# Inherit the roll, then kick up so they peel off while the head drops.
	_glasses_vel = _head_vel + Vector2(0.0, -glasses_up_kick)
	if _glasses_vel.length() < 40.0:
		_glasses_vel = Vector2(220.0, -glasses_up_kick)
	var fly: Tween = create_tween()
	fly.tween_method(_set_glasses_flight, 0.0, glasses_fly_time, glasses_fly_time)
	var spin: Tween = create_tween()
	spin.tween_property(lost_glasses, "rotation", glasses_spin, glasses_fly_time)


## Projectile: x = x0 + v t, y = y0 + v t + ½ g t² (Y-down).
func _set_glasses_flight(t: float) -> void:
	lost_glasses.global_position = (
		_glasses_start
		+ _glasses_vel * t
		+ Vector2(0.0, 0.5 * glasses_gravity * t * t)
	)
