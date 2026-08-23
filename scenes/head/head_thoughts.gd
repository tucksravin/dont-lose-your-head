class_name HeadThoughts
extends Node2D
## Small visual-only stream of lil kikis rising off the head and fading out.
## Lives on head.tscn so every day that instances the Head gets it — no
## per-scene wiring. Not a hazard: no collision, no DayManager.fail. Level
## kikis (rain, flying, swarm, bounce, cloud) stay separate.
##
## Lives as a child of `head.tscn` (no `follow`). Intro / transitions use a
## sprite, not Head — instance this scene there and set `follow` to the
## sprite (or parent it to an unscaled node at the skull). Do not parent it
## to a scale-2 sprite or the thoughts double in size.
##
## Children of this node (not `top_level`): `top_level` treated the local
## offset as a world position and they flew off the top-left. A Tween is the
## idiomatic one-shot mover — no physics.
## Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html

## If set, snap to this node's position each frame (transition head on a path).
@export var follow: Node2D

## Seconds between thoughts. ~0.4 + a 0.8 s rise = a few on screen at once.
@export var interval: float = 0.4
## How far they travel up (px) before they are gone.
@export var rise_px: float = 36.0
## How long the rise + fade lasts.
@export var rise_time: float = 0.8
## Random left/right offset from the skull (px).
@export var jitter_x: float = 6.0
## Spawn point relative to the head centre — just above the 28 px box.
@export var spawn_offset: Vector2 = Vector2(0.0, -14.0)
## Same 2× as other kikis (Kiki.PIXEL_SCALE) so the stream is readable.
@export var kiki_scale: float = 2.0


func _ready() -> void:
	if follow == null:
		# NodePath on an export is relative to *this* node. A path written as
		# if from the scene root (HeadPath/Follow/Head) misses and leaves us
		# at (0,0) — thoughts rise off the top-left. Inherited forks inherit
		# that miss, which is why transition_cage showed nothing.
		follow = get_node_or_null("../HeadPath/Follow/Head") as Node2D
	set_process(follow != null)
	var timer: Timer = Timer.new()
	timer.wait_time = interval
	timer.autostart = true
	timer.timeout.connect(_spawn_one)
	add_child(timer)
	_snap_to_follow()
	_spawn_one()


func _process(_delta: float) -> void:
	_snap_to_follow()


func _snap_to_follow() -> void:
	if follow != null and is_instance_valid(follow):
		global_position = follow.global_position


func _spawn_one() -> void:
	var jitter: Vector2 = Vector2(randf_range(-jitter_x, jitter_x), 0.0)
	var start: Vector2 = spawn_offset + jitter
	var kiki: Kiki = Kiki.spawn(self, &"lil_kiki", start)
	kiki.scale = Vector2(kiki_scale, kiki_scale)
	# Absolute so a day that puts the Head at z_index 1 (tree) still sees them.
	kiki.z_as_relative = false
	kiki.z_index = 10
	var dest: Vector2 = start + Vector2(0.0, -rise_px)
	var tween: Tween = kiki.create_tween()
	tween.set_parallel(true)
	tween.tween_property(kiki, "position", dest, rise_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(kiki, "modulate:a", 0.0, rise_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(kiki.queue_free)
