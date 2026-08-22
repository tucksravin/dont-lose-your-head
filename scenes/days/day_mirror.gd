extends Node2D
## Mirror World (C3d): head on a right-hand platform, staring into a tall
## glass. Look-at-glass inverts walk *and* jump (↓ hops); look-at-player
## restores them. Kikis fly out of the glass toward the body — jump them; a
## hit is `DayManager.fail("kiki")`. **Getting the body within `grab_radius`
## of the glass throws it** — no key press (Tucker, Sat: "when we hit a
## trigger it just happens"); that satisfies both needs and ends the day.
##
## Invert is `Body.move_sign` + `Body.invert_vertical`. Spawn is a Timer
## like ThoughtRain. No SubViewport.

@export var look_hold: float = 2.2
@export var grab_radius: float = 56.0
@export var carry_offset: Vector2 = Vector2(10.0, -36.0)
@export var pickup_time: float = 0.12
@export var throw_release: float = 0.2
@export var throw_time: float = 0.55
@export var chase_delay: float = 0.18
@export var throw_end: Vector2 = Vector2(760.0, 140.0)
@export var throw_spin: float = 4.0
@export var kiki_scene: PackedScene
@export var kiki_interval: float = 1.15
@export var kiki_start_delay: float = 0.8
@export var kiki_speed: float = 200.0
@export var kiki_spawn_offset: Vector2 = Vector2(-22.0, -18.0)
@export var instruction_text: String = "Jump the thoughts. E at the glass throws it. Arrows flip with the head."

@onready var body: CharacterBody2D = $Body
@onready var head: Head = $Head
@onready var mirror: Node2D = $Mirror
@onready var reflection: AnimatedSprite2D = $Mirror/Reflection
@onready var body_need: WinCondition = $BodyNeed
@onready var mind_need: WinCondition = $MindNeed
@onready var instruction: Label = $Instruction

var _staring_at_mirror: bool = true
var _elapsed: float = 0.0
var _done: bool = false
## True only on a real grab. F3 / day_chain satisfy() without this, so
## `_before_head_release` returns at once (same as lockdown's phase guard).
var _threw: bool = false
var _kiki_timer: Timer


func _ready() -> void:
	instruction.text = instruction_text
	if kiki_scene == null:
		kiki_scene = load("res://scenes/gameplay/flying_kiki.tscn") as PackedScene
	_kiki_timer = Timer.new()
	_kiki_timer.wait_time = kiki_interval
	_kiki_timer.timeout.connect(_spawn_kiki)
	add_child(_kiki_timer)
	if kiki_start_delay <= 0.0:
		_kiki_timer.start()
		_spawn_kiki()
	else:
		get_tree().create_timer(kiki_start_delay).timeout.connect(_on_kiki_start)
	_apply_look()
	Events.day_completed.connect(_stop)
	Events.day_failed.connect(_stop_failed)


func _on_kiki_start() -> void:
	if _done or not is_inside_tree():
		return
	_spawn_kiki()
	_kiki_timer.start()


func _process(delta: float) -> void:
	if _done:
		return
	_elapsed += delta
	if _elapsed >= look_hold:
		_elapsed = 0.0
		_staring_at_mirror = not _staring_at_mirror
		_apply_look()
	# Getting to the mirror IS the throw — no key (Tucker, Sat). _try_grab()
	# already range-checks against grab_radius and _threw guards the repeat.
	_try_grab()


func _apply_look() -> void:
	# Glass is on the right of the head: +x = stare at the glass.
	if _staring_at_mirror:
		head.look(1)
		body.set("move_sign", -1.0)
		body.set("invert_vertical", true)
		_play_reflection(&"look_left")
	else:
		head.look(-1)
		body.set("move_sign", 1.0)
		body.set("invert_vertical", false)
		_play_reflection(&"look_right")


func _play_reflection(anim: StringName) -> void:
	if reflection == null or reflection.sprite_frames == null:
		return
	var frames: SpriteFrames = reflection.sprite_frames
	var glasses_anim: StringName = &""
	if anim == &"look_left":
		glasses_anim = &"glasses_look_left"
	elif anim == &"look_right":
		glasses_anim = &"glasses_look_right"
	if Game.wearing_glasses and glasses_anim != &"" and frames.has_animation(glasses_anim):
		reflection.play(glasses_anim)
	elif frames.has_animation(anim):
		reflection.play(anim)


func _try_grab() -> void:
	if _threw:
		return
	if body.global_position.distance_to(mirror.global_position) > grab_radius:
		return
	_threw = true
	_stop()
	mind_need.satisfy()
	body_need.satisfy()


func _spawn_kiki() -> void:
	if _done or kiki_scene == null:
		return
	var kiki: Node2D = kiki_scene.instantiate() as Node2D
	if kiki == null:
		return
	kiki.global_position = mirror.global_position + kiki_spawn_offset
	var toward: Vector2 = body.global_position - mirror.global_position
	toward.y = 0.0
	if toward.x == 0.0:
		toward.x = -1.0
	kiki.set("direction", toward)
	kiki.set("speed", kiki_speed)
	add_child(kiki)


## DayManager awaits this before `head.release()`. Pickup → throw sheet →
## glass flies right; we return mid-flight so the head chases it.
func _before_head_release() -> void:
	if not _threw:
		return
	body.set("is_scripted", true)
	body.velocity = Vector2.ZERO
	var sprite: AnimatedSprite2D = body.get_node_or_null("Visual") as AnimatedSprite2D
	if sprite != null:
		sprite.flip_h = false
	if reflection != null:
		reflection.visible = false
	var hands: Vector2 = body.global_position + carry_offset
	var lift: Tween = create_tween()
	lift.tween_property(mirror, "global_position", hands, pickup_time)\
		.set_ease(Tween.EASE_OUT)
	await lift.finished
	if not is_instance_valid(mirror):
		return
	if body.has_method("play_throw"):
		body.call("play_throw")
	await get_tree().create_timer(throw_release).timeout
	if not is_instance_valid(mirror):
		return
	var fly: Tween = create_tween()
	fly.set_parallel(true)
	fly.tween_property(mirror, "global_position", throw_end, throw_time)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	fly.tween_property(mirror, "rotation", throw_spin, throw_time)
	await get_tree().create_timer(chase_delay).timeout


func _stop() -> void:
	_done = true
	body.set("move_sign", 1.0)
	body.set("invert_vertical", false)
	if _kiki_timer != null:
		_kiki_timer.stop()
	for child in get_tree().get_nodes_in_group("flying_kiki"):
		child.queue_free()


func _stop_failed(_reason: String) -> void:
	_stop()
