extends Node2D
## Reunion — the upside-down ending (brainstorm: walk in flipped, dive,
## bounce to standing, screen rights, walk off into the sunset).
##
## Camera2D.zoom.y = -1 flips the view vertically (the floor reads as the
## ceiling) without mirroring left/right, so A/D still walk toward the head.
## The dive is the existing Tween. Then we un-flip the camera and un-rotate
## the actors together (bounce onto their feet), `Head.attach` the skull, and
## script-walk them off the right toward a parked sun sprite — not `sun.tscn`,
## which is the day timer.
##
## Docs: https://docs.godotengine.org/en/stable/classes/class_camera2d.html
## Tween: https://docs.godotengine.org/en/stable/classes/class_tween.html

enum Phase { WALKING, MERGING, RIGHTING, SUNSET, DONE }

@export var interact_distance: float = 64.0
@export var dive_rise: float = 0.32
@export var dive_fall: float = 0.22
@export var dive_apex: float = 56.0
@export var landing_offset: Vector2 = Vector2(0, -56)
@export var right_time: float = 0.55
@export var bounce_apex: float = 28.0
@export var land_time: float = 0.18
@export var attach_offset: Vector2 = Vector2(0.0, -40.0)
@export var walk_off_speed: float = 150.0
@export var exit_x: float = 700.0
@export var fade_duration: float = 0.8
@export var next_scene: String = "res://scenes/main.tscn"

@onready var head_blob: Head = $Head
@onready var body_blob: CharacterBody2D = $Body
@onready var camera: Camera2D = $Camera2D
@onready var interact_prompt: Label = $InteractPrompt
@onready var fade: ColorRect = $FadeOverlay/Fade

var phase: Phase = Phase.WALKING
var _fading: bool = false


func _ready() -> void:
	# zoom.y = -1 turns the 640×360 frame upside down without swapping
	# left/right. CanvasLayer fade is screen-space, so it stays upright.
	camera.zoom = Vector2(1.0, -1.0)
	# World-space label would read upside-down; flip it so E is still E.
	interact_prompt.scale = Vector2(1.0, -1.0)


func _physics_process(_delta: float) -> void:
	if phase == Phase.WALKING:
		_check_interact()
	elif phase == Phase.SUNSET:
		_walk_off()


func _check_interact() -> void:
	var dist: float = body_blob.global_position.distance_to(head_blob.global_position)
	interact_prompt.visible = dist < interact_distance
	if dist < interact_distance and Input.is_action_just_pressed("interact"):
		_begin_merge()


func _begin_merge() -> void:
	phase = Phase.MERGING
	interact_prompt.visible = false

	var body_sprite: AnimatedSprite2D = body_blob.get_node_or_null("Visual") as AnimatedSprite2D
	if body_sprite != null:
		body_sprite.play(&"idle")
		body_sprite.frame = 0
	var juice: Node = body_blob.get_node_or_null("Juice")
	if juice != null and juice.has_method("reset"):
		juice.call("reset")

	body_blob.process_mode = Node.PROCESS_MODE_DISABLED

	var landing: Vector2 = head_blob.global_position + landing_offset
	var apex: Vector2 = Vector2(
			(body_blob.global_position.x + landing.x) * 0.5,
			landing.y - dive_apex)

	var tw: Tween = create_tween()
	Sfx.play(&"dive")
	tw.tween_property(body_blob, "global_position", apex, dive_rise)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(body_blob, "rotation", PI, dive_rise)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(body_blob, "global_position", landing, dive_fall)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(Sfx.play.bind(&"reunite"))
	tw.tween_callback(_begin_righting)


func _begin_righting() -> void:
	phase = Phase.RIGHTING
	var stand_x: float = head_blob.global_position.x
	var bounce: Vector2 = Vector2(stand_x, 320.0 - bounce_apex)
	var stand_body: Vector2 = Vector2(stand_x, 320.0)
	var stand_head: Vector2 = Vector2(stand_x, 306.0)

	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(camera, "zoom", Vector2(1.0, 1.0), right_time)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(body_blob, "rotation", 0.0, right_time)\
		.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(head_blob, "rotation", 0.0, right_time)\
		.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(body_blob, "global_position", bounce, right_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(head_blob, "global_position", stand_head, right_time)
	tw.set_parallel(false)
	tw.tween_property(body_blob, "global_position", stand_body, land_time)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_begin_sunset)


func _begin_sunset() -> void:
	phase = Phase.SUNSET
	body_blob.rotation = 0.0
	body_blob.process_mode = Node.PROCESS_MODE_INHERIT
	body_blob.set("is_scripted", true)
	body_blob.velocity = Vector2.ZERO
	if head_blob.has_method("attach"):
		head_blob.attach(body_blob, attach_offset)


func _walk_off() -> void:
	if _fading:
		return
	body_blob.velocity.x = walk_off_speed
	body_blob.velocity.y = 0.0
	body_blob.move_and_slide()
	if body_blob.global_position.x >= exit_x:
		_fade_out()


func _fade_out() -> void:
	if _fading:
		return
	_fading = true
	phase = Phase.DONE
	var tw: Tween = create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, fade_duration)
	tw.tween_callback(func() -> void:
		Game.change_scene(next_scene)
	)
