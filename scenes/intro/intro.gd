extends Node2D
## Intro scene — two-blob chase (first iteration).
##
## Head blob (yellow square) moves right at a scripted speed; player controls
## the body blob (blue rectangle) immediately from frame 1.
##
## When the head exits the right viewport edge, both blobs auto-scroll off
## screen, then the next scene loads.
##
## NOTE: Camera2D is static (fixed at viewport centre) rather than parented to
## HeadBlob. This lets the head visibly run off the right edge — the whole
## point of the intro shot. Game-day scenes will follow the head instead.
##
## TODO(cutscene): Before Phase.CHASE, add a short Tween separation animation:
##   skeleton stands still → intrusive thoughts appear →
##   head "pops" off (scale bounce + rightward Tween) → CHASE begins.
##   Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html

enum Phase { CHASE, EXIT }

## Head blob rightward speed in pixels per second.
@export var head_speed: float = 150.0
## Horizontal speed cap for the player-controlled body blob.
@export var body_speed: float = 220.0
## Upward impulse on jump. Negative because Godot's Y axis points down.
@export var jump_velocity: float = -400.0
## Downward gravity acceleration (px/s²).
@export var gravity: float = 980.0
## Pixels past the right viewport edge before EXIT triggers.
@export var exit_margin: float = 120.0
## Seconds to wait after triggering EXIT before changing scene.
@export var exit_delay: float = 1.2
## Scene to load after the intro. Points at reunion for end-to-end testing;
## swap for res://scenes/days/day_01.tscn when day 1 exists.
@export var next_scene: String = "res://scenes/reunion/reunion.tscn"

@onready var head_blob: CharacterBody2D = $HeadBlob
@onready var body_blob: CharacterBody2D = $BodyBlob

var phase: Phase = Phase.CHASE
var _exiting: bool = false


func _physics_process(delta: float) -> void:
	match phase:
		Phase.CHASE:
			_move_head(delta)
			_move_body(delta)
			_check_exit()
		Phase.EXIT:
			_scroll_blob(head_blob, delta)
			_scroll_blob(body_blob, delta)


## Scripted rightward movement for the head blob.
func _move_head(delta: float) -> void:
	head_blob.velocity.x = head_speed
	if head_blob.is_on_floor():
		head_blob.velocity.y = 0.0
	else:
		head_blob.velocity.y += gravity * delta
	head_blob.move_and_slide()


## Player-controlled movement for the body blob.
## Uses move_left / move_right / jump input actions (defined in project.godot).
func _move_body(delta: float) -> void:
	var dir: float = Input.get_axis("move_left", "move_right")
	body_blob.velocity.x = dir * body_speed
	if body_blob.is_on_floor():
		body_blob.velocity.y = 0.0
		if Input.is_action_just_pressed("jump"):
			body_blob.velocity.y = jump_velocity
	else:
		body_blob.velocity.y += gravity * delta
	body_blob.move_and_slide()


## Check whether the head has exited the right side of the viewport.
## get_viewport_rect() returns the viewport in screen pixels (0,0)→(640,360)
## regardless of camera position. With a static camera centred at (320,180)
## those values map 1-to-1 to world coordinates.
func _check_exit() -> void:
	if _exiting:
		return
	var right_edge: float = get_viewport_rect().size.x
	if head_blob.global_position.x > right_edge + exit_margin:
		_exiting = true
		phase = Phase.EXIT
		get_tree().create_timer(exit_delay).timeout.connect(_on_exit_delay)


## Move a blob rightward with gravity; used in EXIT phase.
func _scroll_blob(blob: CharacterBody2D, delta: float) -> void:
	blob.velocity.x = head_speed
	if blob.is_on_floor():
		blob.velocity.y = 0.0
	else:
		blob.velocity.y += gravity * delta
	blob.move_and_slide()


func _on_exit_delay() -> void:
	Game.change_scene(next_scene)
