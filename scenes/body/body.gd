extends CharacterBody2D
## Body — the player-controlled skeleton torso. Walks left/right and jumps.

@export var speed: float = 150.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 980.0


func _physics_process(delta: float) -> void:
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
