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
