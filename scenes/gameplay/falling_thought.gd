extends Area2D
## One falling intrusive thought. Area2D so it doesn't block walking; a hit on
## the body fails the day. The head is a RigidBody2D, so the CharacterBody2D
## check leaves it alone.

@export var fall_speed: float = 140.0

var _failed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	position.y += fall_speed * delta
	if position.y > 400.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _failed or not body is CharacterBody2D:
		return
	_failed = true
	var manager: Node = get_tree().get_first_node_in_group("day_manager")
	if manager != null and manager.has_method("fail"):
		manager.call("fail", "hit")
	queue_free()
