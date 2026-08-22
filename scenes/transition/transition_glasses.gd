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
## Arc: up above the head, then off the right edge. Two Tweens (rise / fall)
## — same pattern as the reunion dive. Godot Tweens are straight lines, so
## the arc is two beats, not a curve resource.
@export var glasses_apex_height: float = 88.0
@export var glasses_apex_right: float = 90.0
@export var glasses_end: Vector2 = Vector2(720.0, 120.0)
@export var glasses_rise: float = 0.28
@export var glasses_fall: float = 0.5
@export var glasses_spin: float = 8.0
## After the path ends, keep rolling off the right (seconds).
@export var exit_time: float = 0.65
@export var exit_end: Vector2 = Vector2(720.0, 348.0)
@export var exit_spin: float = 3.5

@onready var lost_glasses: Sprite2D = $LostGlasses

var _glasses_flew: bool = false


## Full beat. Do not call super — the new base parks until the body is close,
## then rolls and stops. This beat never parks.
func _run() -> void:
	# Same spin setup as the base so `_process` can rotate the skull.
	var total: float = path.curve.get_baked_length()
	var turns: int = maxi(1, roundi(total / (TAU * head_radius)))
	_spin = float(turns) * TAU / total
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
	var start: Vector2 = head.global_position
	var apex: Vector2 = Vector2(start.x + glasses_apex_right, start.y - glasses_apex_height)
	var fly: Tween = create_tween()
	fly.tween_property(lost_glasses, "global_position", apex, glasses_rise)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	fly.tween_property(lost_glasses, "global_position", glasses_end, glasses_fall)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	var spin: Tween = create_tween()
	spin.tween_property(lost_glasses, "rotation", glasses_spin, glasses_rise + glasses_fall)
