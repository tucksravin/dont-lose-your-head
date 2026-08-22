extends CharacterBody2D
## Body — the player-controlled skeleton torso. Walks left/right and jumps.

@export var speed: float = 150.0
@export var jump_velocity: float = -300.0
@export var gravity: float = 980.0
## Multiply the walk axis. 1 = normal; −1 = left/right swapped (mirror day).
## Other days leave this at 1. Sprite still faces travel, not the key pressed.
@export var move_sign: float = 1.0
## When true, jump reads `move_down` (↓) instead of `jump` (↑ / Space / W).
## Mirror day flips this with the head's look. Other days leave it false.
@export var invert_vertical: bool = false

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
	# throw is a one-shot (body_frames, 3 frames, no loop). Don't stomp it
	# with idle/walk — the mirror day plays it, then the sheet holds the last
	# frame until something else calls play().
	if _sprite.animation == &"throw":
		return
	if absf(velocity.x) > 1.0:
		_sprite.flip_h = velocity.x < 0.0
		if _sprite.animation != &"walk":
			_sprite.play(&"walk")
	elif _sprite.animation != &"idle":
		_sprite.play(&"idle")


## Play the authored throw sheet. No-op if the frames aren't there.
func play_throw() -> void:
	if _sprite != null and _sprite.sprite_frames.has_animation(&"throw"):
		_sprite.play(&"throw")


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

	if _jump_requested() and is_on_floor():
		velocity.y = jump_velocity
		jumped.emit()

	var direction: float = Input.get_axis("move_left", "move_right") * move_sign
	if direction != 0.0:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

	move_and_slide()
	_track_landing()


func _jump_requested() -> bool:
	if invert_vertical:
		return Input.is_action_just_pressed("move_down")
	return Input.is_action_just_pressed("jump")


## Emit `landed` on the air→floor edge. Called after move_and_slide() so
## is_on_floor() is fresh; also called in scripted mode (a cutscene driving
## move_and_slide() from outside still lands).
func _track_landing() -> void:
	var on_floor: bool = is_on_floor()
	if on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = on_floor
