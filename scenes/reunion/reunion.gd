extends Node2D
## Reunion scene.
##
## Player walks the body blob (blue) toward the stationary head blob (yellow).
## When within interact_distance and the player presses "interact", a Tween
## snaps the body to the head, then fades to black, then loads next_scene.
##
## Tween — Godot's built-in interpolator; create_tween() ties its lifetime to
## the scene tree so it cleans itself up automatically.
## Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html
##
## TODO(cutscene): Later iteration — after the snap, play a short sequence where
## the head turns to face the camera and the body walks into the screen before
## the fade. That would live here as additional tween steps after Phase.MERGING.

enum Phase { WALKING, MERGING, DONE }

## Horizontal speed cap for the player-controlled body blob (px/s).
@export var body_speed: float = 220.0
## Upward impulse on jump. Negative because Godot's Y axis points down.
@export var jump_velocity: float = -400.0
## Downward gravity acceleration (px/s²).
@export var gravity: float = 980.0
## Distance in pixels at which the interact prompt appears and "interact" works.
@export var interact_distance: float = 64.0
## Duration of the body-snaps-to-head animation (seconds).
@export var merge_duration: float = 0.4
## Duration of the fade-to-black (seconds).
@export var fade_duration: float = 0.8
## Scene to load after the reunion. Swap for the real ending / credits when ready.
@export var next_scene: String = "res://scenes/main.tscn"

@onready var head_blob: CharacterBody2D = $HeadBlob
@onready var body_blob: CharacterBody2D = $BodyBlob
@onready var interact_prompt: Label = $InteractPrompt
@onready var fade: ColorRect = $FadeOverlay/Fade

var phase: Phase = Phase.WALKING


func _physics_process(delta: float) -> void:
	match phase:
		Phase.WALKING:
			_settle_head(delta)
			_move_body(delta)
			_check_interact()
		Phase.MERGING, Phase.DONE:
			pass


## Keep the head blob on the floor via gravity; it doesn't move horizontally.
func _settle_head(delta: float) -> void:
	if head_blob.is_on_floor():
		head_blob.velocity.y = 0.0
	else:
		head_blob.velocity.y += gravity * delta
	head_blob.move_and_slide()


## Player-controlled movement for the body blob.
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


## Show/hide the prompt and handle the interact press.
func _check_interact() -> void:
	var dist: float = body_blob.global_position.distance_to(head_blob.global_position)
	interact_prompt.visible = dist < interact_distance
	if dist < interact_distance and Input.is_action_just_pressed("interact"):
		_begin_merge()


## Kick off the merge → fade → scene-change tween chain.
## Tween steps run sequentially; the scene change fires as a callback at the end.
func _begin_merge() -> void:
	phase = Phase.MERGING
	interact_prompt.visible = false

	var tw: Tween = create_tween()
	# Step 1: snap body to head position.
	tw.tween_property(body_blob, "global_position",
			head_blob.global_position, merge_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Step 2: fade screen to black.
	tw.tween_property(fade, "modulate:a", 1.0, fade_duration)
	# Step 3: load the next scene once fade is complete.
	tw.tween_callback(func() -> void:
		phase = Phase.DONE
		Game.change_scene(next_scene)
	)
