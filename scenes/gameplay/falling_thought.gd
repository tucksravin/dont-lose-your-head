extends Area2D
## One falling intrusive thought. Area2D so it doesn't block walking; a hit on
## the body fails the day. The head is a RigidBody2D, so the CharacterBody2D
## check leaves it alone.
##
## Lockdown: `launch_then_rain` first sends it **up** from the head and off
## the top (no hit). Then it appears at the rain spawn and falls as before
## (interval / speed / miss_mult stay on ThoughtRain).

@export var fall_speed: float = 140.0

var _failed: bool = false
var _rising: bool = false
var _rain_at: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Rise off the top, then fall from `rain_at` (ThoughtRain's random-x slot).
func launch_then_rain(rain_at: Vector2) -> void:
	_rising = true
	_rain_at = rain_at
	monitoring = false


func _process(delta: float) -> void:
	if _rising:
		position.y -= fall_speed * delta
		if position.y < -16.0:
			_rising = false
			position = _rain_at
			monitoring = true
		return
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
