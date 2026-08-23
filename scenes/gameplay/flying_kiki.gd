extends Area2D
## One kiki flying as a hazard. Area2D so it doesn't shove the body; a hit
## fails the day (same as FallingThought). The head is a RigidBody2D, so the
## CharacterBody2D check leaves it alone.
##
## Two flights: **straight** (panic — left from a spawn point) and **head
## arc** (mirror — out of the skull, curve right, drop, then horizontal at
## the player). `start_head_arc()` runs a cubic Bézier in `_process`; a Tween
## would also work, but one `_process` keeps both flights in one place.
## Docs: https://docs.godotengine.org/en/stable/tutorials/physics/using_area_2d.html

@export var speed: float = 200.0
@export var frames: SpriteFrames
## How far right of the head the mirror arc peaks (px).
@export var arc_right: float = 48.0
## Seconds for the right-then-down curve. After this it flies left.
@export var arc_time: float = 0.55
## World y of the horizontal run (body jump height).
@export var approach_y: float = 300.0

var direction: Vector2 = Vector2.LEFT
var _failed: bool = false
var _arcing: bool = false
var _arc_t: float = 0.0
var _p0: Vector2 = Vector2.ZERO
var _p1: Vector2 = Vector2.ZERO
var _p2: Vector2 = Vector2.ZERO
var _p3: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("flying_kiki")
	body_entered.connect(_on_body_entered)
	# $Visual is a Kiki (scenes/gameplay/kiki.gd): it loads kiki_frames itself and
	# scrambles its start frame + 90° rotation in its own _ready(), which runs
	# BEFORE this one (children are ready first). Touching it here would restart
	# the animation on frame 0 and undo the scramble, so leave it alone; `frames`
	# stays as an override hook for anyone who wants different art.
	var sprite: AnimatedSprite2D = $Visual
	if sprite != null and not (sprite is Kiki) and frames != null:
		sprite.sprite_frames = frames
		if frames.has_animation(&"lil_kiki"):
			sprite.play(&"lil_kiki")


## Spawn at `from` (the head), curve right, drop to `approach_y`, then fly left.
func start_head_arc(from: Vector2) -> void:
	_p0 = from
	_p1 = from + Vector2(arc_right, 0.0)
	_p2 = Vector2(from.x + arc_right, from.y)
	_p3 = Vector2(from.x + arc_right, approach_y)
	_arc_t = 0.0
	_arcing = true
	global_position = from
	direction = Vector2.LEFT


func _process(delta: float) -> void:
	if _arcing:
		_arc_t += delta / maxf(arc_time, 0.01)
		if _arc_t >= 1.0:
			_arcing = false
			global_position = _p3
		else:
			global_position = _cubic(_p0, _p1, _p2, _p3, _arc_t)
		return
	var travel: Vector2 = direction
	travel.y = 0.0
	if travel.x == 0.0:
		travel.x = -1.0
	position += travel.normalized() * speed * delta
	if position.x < -40.0 or position.x > 680.0:
		queue_free()


func _cubic(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var u: float = 1.0 - t
	return u * u * u * a + 3.0 * u * u * t * b + 3.0 * u * t * t * c + t * t * t * d


func _on_body_entered(body: Node2D) -> void:
	if _failed or not body is CharacterBody2D:
		return
	# Panic's release button puts the body in this group so standing on
	# it is safe. Mirror day never adds it, so a hit there still fails.
	if body.is_in_group("kiki_safe"):
		return
	_failed = true
	var manager: Node = get_tree().get_first_node_in_group("day_manager")
	if manager != null and manager.has_method("fail"):
		manager.call("fail", "kiki")
	queue_free()
