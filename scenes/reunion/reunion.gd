extends Node2D
## Reunion scene.
##
## Player walks the body (body.tscn, CharacterBody2D) toward the stationary
## head (head.tscn, RigidBody2D). body.gd drives player input automatically.
## head.tscn ships with freeze = true, so it is placed directly on the floor in
## the scene rather than dropped onto it — no gravity, no settling. head.gd's
## release() is never called here, so the head stays put for good.
##
## When within interact_distance and the player presses "interact", a chained
## Tween dives the body onto the upside-down head, fades to black, then loads
## next_scene.
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
## The dive, in two beats: the body leaves the ground and turns over (rise),
## then drops onto the head (fall). Seconds.
@export var dive_rise: float = 0.32
@export var dive_fall: float = 0.22
## How far above the landing point the body arcs on the way over (pixels).
@export var dive_apex: float = 56.0
## Where the body's origin finishes, relative to the head's origin. By then the
## body is upside down, so the neck — the sprite's bottom edge once flipped —
## is what rests on the top of the skull. -56 seats them with no gap and no
## overlap; re-measure if either sprite's height changes.
@export var landing_offset: Vector2 = Vector2(0, -56)
## Duration of the fade-to-black (seconds).
@export var fade_duration: float = 0.8
## Scene to load after the reunion. Swap for credits / ending when ready.
@export var next_scene: String = "res://scenes/main.tscn"

## head.tscn root is a frozen RigidBody2D — a prop, it never moves here.
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
## body.gd drives the body; the head is frozen and never moves in this scene.
func _check_interact() -> void:
	var dist: float = body_blob.global_position.distance_to(head_blob.global_position)
	interact_prompt.visible = dist < interact_distance
	if dist < interact_distance and Input.is_action_just_pressed("interact"):
		_begin_merge()


## Kick off the merge → fade → scene-change tween chain.
func _begin_merge() -> void:
	phase = Phase.MERGING
	interact_prompt.visible = false

	# Pin the sprite to a known pose FIRST. process_mode DISABLED below stops the
	# AnimatedSprite2D too, so it freezes on whatever frame it happened to be
	# showing — and the walk frames are a few pixels shorter than idle, which
	# moved the landing height run to run. Pinning idle makes the ending land
	# identically every time.
	var body_sprite: AnimatedSprite2D = body_blob.get_node_or_null("Visual") as AnimatedSprite2D
	if body_sprite != null:
		body_sprite.play(&"idle")
		body_sprite.frame = 0
	# And the procedural juice (breathing / lean) — same reason, same moment.
	var juice: Node = body_blob.get_node_or_null("Juice")
	if juice != null and juice.has_method("reset"):
		juice.call("reset")

	# Disable body.gd so it stops reading input and calling move_and_slide().
	# With process_mode DISABLED, the CharacterBody2D holds position, letting
	# the Tween set global_position directly without fighting physics.
	body_blob.process_mode = Node.PROCESS_MODE_DISABLED

	# The head is already lying upside down (rotation is set in reunion.tscn), so
	# the body dives head-first onto it and finishes upside down too — balanced
	# on the skull. Both land seated on their own lowest pixel, not floating.
	var landing: Vector2 = head_blob.global_position + landing_offset
	var apex: Vector2 = Vector2(
			(body_blob.global_position.x + landing.x) * 0.5,
			landing.y - dive_apex)

	var tw: Tween = create_tween()
	Sfx.play(&"dive")
	# Step 1: up and over — the turn happens on the way up, in parallel with the
	# rise so both finish together and step 2 starts clean.
	tw.tween_property(body_blob, "global_position", apex, dive_rise)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(body_blob, "rotation", PI, dive_rise)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Step 2: the dive down onto the head — EASE_IN so it accelerates.
	tw.tween_property(body_blob, "global_position", landing, dive_fall)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(Sfx.play.bind(&"reunite"))
	# Step 3: fade screen to black.
	tw.tween_property(fade, "modulate:a", 1.0, fade_duration)
	# Step 4: load the next scene once the fade completes.
	tw.tween_callback(func() -> void:
		phase = Phase.DONE
		Game.change_scene(next_scene)
	)
