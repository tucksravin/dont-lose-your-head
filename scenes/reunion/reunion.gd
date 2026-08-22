extends Node2D
## Reunion scene.
##
## Player walks the body (body.tscn, CharacterBody2D) toward the stationary
## head (head.tscn, RigidBody2D). body.gd drives player input automatically.
## head.tscn settles on the floor via its own RigidBody2D physics — no manual
## gravity needed here.
##
## When within interact_distance and the player presses "interact", a chained
## Tween snaps the body to the head, fades to black, then loads next_scene.
##
## Tween — Godot's built-in interpolator; create_tween() ties its lifetime to
## the scene tree so it cleans itself up automatically.
## Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html
##
## TODO(cutscene): Later iteration — after the snap, play a short sequence where
## the head turns to face the camera and the body walks into the screen before
## the fade. That would live here as additional tween steps after Phase.MERGING.

enum Phase { WALKING, MERGING, DONE }

## Distance in pixels at which the interact prompt appears and "interact" works.
@export var interact_distance: float = 64.0
## Duration of the body-snaps-to-head animation (seconds).
@export var merge_duration: float = 0.4
## Duration of the fade-to-black (seconds).
@export var fade_duration: float = 0.8
## Scene to load after the reunion. Swap for credits / ending when ready.
@export var next_scene: String = "res://scenes/main.tscn"

## head.tscn root is a RigidBody2D — physics settles it on the floor for free.
@onready var head_blob: RigidBody2D = $Head
## body.tscn root is a CharacterBody2D — body.gd drives player input.
@onready var body_blob: CharacterBody2D = $Body
@onready var interact_prompt: Label = $InteractPrompt
@onready var fade: ColorRect = $FadeOverlay/Fade

var phase: Phase = Phase.WALKING


func _physics_process(_delta: float) -> void:
	if phase == Phase.WALKING:
		_check_interact()


## Show/hide the prompt and handle the interact press.
## body.gd and head.tscn's RigidBody2D handle movement on their own.
func _check_interact() -> void:
	var dist: float = body_blob.global_position.distance_to(head_blob.global_position)
	interact_prompt.visible = dist < interact_distance
	if dist < interact_distance and Input.is_action_just_pressed("interact"):
		_begin_merge()


## Kick off the merge → fade → scene-change tween chain.
func _begin_merge() -> void:
	phase = Phase.MERGING
	interact_prompt.visible = false

	# Freeze the head so physics doesn't shift it mid-animation.
	# RigidBody2D.freeze = true halts all physics simulation on that body.
	head_blob.freeze = true

	# Disable body.gd so it stops reading input and calling move_and_slide().
	# With process_mode DISABLED, the CharacterBody2D holds position, letting
	# the Tween set global_position directly without fighting physics.
	body_blob.process_mode = Node.PROCESS_MODE_DISABLED

	var tw: Tween = create_tween()
	# Step 1: snap body to head position.
	tw.tween_property(body_blob, "global_position",
			head_blob.global_position, merge_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	# Step 2: fade screen to black.
	tw.tween_property(fade, "modulate:a", 1.0, fade_duration)
	# Step 3: load the next scene once the fade completes.
	tw.tween_callback(func() -> void:
		phase = Phase.DONE
		Game.change_scene(next_scene)
	)
