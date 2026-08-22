extends Area2D
## Stationary kiki you can stomp. Area2D so it does not shove the body.
## Falling onto its head bounces you (`velocity.y`) and emits `stomped`
## (the day drops this kiki onto the button). Any other contact is
## `DayManager.fail("kiki")` — same as FlyingKiki.
## Docs: https://docs.godotengine.org/en/stable/tutorials/physics/using_area_2d.html

signal stomped

@export var frames: SpriteFrames
@export var bounce_velocity: float = -280.0
@export var hover_amp: float = 6.0
@export var hover_speed: float = 2.2
## How far below the kiki's centre the body's feet may be and still count
## as a stomp (px). Body origin is its feet.
@export var stomp_slop: float = 8.0

var _base: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _dead: bool = false
var _hovering: bool = true


func _ready() -> void:
	_base = position
	body_entered.connect(_on_body_entered)
	var sprite: AnimatedSprite2D = $Visual
	if frames != null and sprite != null:
		sprite.sprite_frames = frames
	if sprite != null and sprite.sprite_frames != null:
		if sprite.sprite_frames.has_animation(&"big_kiki"):
			sprite.play(&"big_kiki")
		elif sprite.sprite_frames.has_animation(&"lil_kiki"):
			sprite.play(&"lil_kiki")
		var count: int = sprite.sprite_frames.get_frame_count(sprite.animation)
		if count > 0:
			sprite.set_frame_and_progress(randi() % count, randf())


func _process(delta: float) -> void:
	if not _hovering:
		return
	_t += delta
	position = _base + Vector2(0.0, sin(_t * hover_speed) * hover_amp)


func _on_body_entered(body: Node2D) -> void:
	if _dead or not body is CharacterBody2D:
		return
	var walker: CharacterBody2D = body as CharacterBody2D
	var from_above: bool = walker.global_position.y <= global_position.y + stomp_slop
	if walker.velocity.y > 40.0 and from_above:
		walker.velocity.y = bounce_velocity
		_hovering = false
		monitoring = false
		stomped.emit()
		return
	_dead = true
	var manager: Node = get_tree().get_first_node_in_group("day_manager")
	if manager != null and manager.has_method("fail"):
		manager.call("fail", "kiki")
