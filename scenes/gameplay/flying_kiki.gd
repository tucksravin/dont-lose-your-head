extends Area2D
## One kiki flying horizontally out of the mirror. Area2D so it doesn't
## shove the body; a hit fails the day (same as FallingThought). The head
## is a RigidBody2D, so the CharacterBody2D check leaves it alone.
##
## Docs: https://docs.godotengine.org/en/stable/tutorials/physics/using_area_2d.html

@export var speed: float = 200.0
@export var frames: SpriteFrames

var direction: Vector2 = Vector2.LEFT
var _failed: bool = false


func _ready() -> void:
	add_to_group("flying_kiki")
	body_entered.connect(_on_body_entered)
	var sprite: AnimatedSprite2D = $Visual
	if frames != null and sprite != null:
		sprite.sprite_frames = frames
		if frames.has_animation(&"lil_kiki"):
			sprite.play(&"lil_kiki")


func _process(delta: float) -> void:
	var travel: Vector2 = direction
	travel.y = 0.0
	if travel.x == 0.0:
		travel.x = -1.0
	position += travel.normalized() * speed * delta
	if position.x < -40.0 or position.x > 680.0:
		queue_free()


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
