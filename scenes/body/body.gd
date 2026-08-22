extends CharacterBody2D
## Body — the player-controlled skeleton torso. Walks left/right and jumps.

@export var speed: float = 150.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 980.0

## The body left the ground by jumping (not by walking off a ledge).
signal jumped
## The body touched down after being in the air. Sound and animation listen;
## this script doesn't know or care what they do with it.
signal landed

## When true, this node ignores player input — an external script (e.g. a
## cutscene) is driving velocity/move_and_slide() on it directly instead.
## Prefer this over Node.PROCESS_MODE_DISABLED: DISABLED also pulls a
## CharacterBody2D out of the physics space, so any move_and_slide() call
## made on it from elsewhere (even from a script that's still enabled)
## fails with "body->get_space() is null".
var is_scripted: bool = false

var _was_on_floor: bool = true

## Sprite animation: "walk" while moving, "idle" otherwise; faces the direction of travel.
## Driven by velocity (not input) so cutscenes that set velocity directly animate too.
@onready var _sprite: AnimatedSprite2D = $Visual


func _process(_delta: float) -> void:
	if absf(velocity.x) > 1.0:
		_sprite.flip_h = velocity.x < 0.0
		if _sprite.animation != &"walk":
			_sprite.play(&"walk")
	elif _sprite.animation != &"idle":
		_sprite.play(&"idle")


func _ready() -> void:
	# Same idiom head.gd uses: a script that wants "the" body (e.g.
	# PanicCounter) shouldn't need a hard node path to find it.
	add_to_group("body")


func _physics_process(delta: float) -> void:
	if is_scripted:
		_track_landing()
		return
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		jumped.emit()

	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()
	_track_landing()


## Emit `landed` on the air→floor edge. Called after move_and_slide() so
## is_on_floor() is fresh; also called in scripted mode (a cutscene driving
## move_and_slide() from outside still lands).
func _track_landing() -> void:
	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor
