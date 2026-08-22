extends CharacterBody2D
## Body — the player-controlled skeleton torso. Walks left/right and jumps.

@export var speed: float = 150.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 980.0

## When true, this node ignores player input — an external script (e.g. a
## cutscene) is driving velocity/move_and_slide() on it directly instead.
## Prefer this over Node.PROCESS_MODE_DISABLED: DISABLED also pulls a
## CharacterBody2D out of the physics space, so any move_and_slide() call
## made on it from elsewhere (even from a script that's still enabled)
## fails with "body->get_space() is null".
var is_scripted: bool = false


func _physics_process(delta: float) -> void:
	if is_scripted:
		return
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()
