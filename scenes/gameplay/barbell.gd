class_name Barbell
extends Area2D
## Floor barbell: **walking into it picks it up** — no key (Tucker, Sat:
## "when we hit a trigger it just happens"). Area2D so it doesn't push.
##
## Art is `barbell_frames.tres` (Tucker): `alone` on the floor, `with_body`
## when held, `lifting` (squat → press, 10 fps) on each mash. Frames 1–3
## *include* the skeleton, so pickup hides the body's `Visual` and this
## sprite stands in for body + bar. Same 2× / `centered = false` /
## `offset (-16,-32)` as the body, so the cell's feet sit on the node.
##
## Docs: https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html

signal picked_up

## While held, sit on the carrier's origin (feet). Zero because the lift
## frames are a full body, not a bar floating above one.
@export var carry_offset: Vector2 = Vector2.ZERO

@onready var prompt: Label = $Prompt
@onready var visual: AnimatedSprite2D = $Visual
## Same files Body's jump uses, but picked at random each pump rather than
## cycled in order — mashing is rapid-fire, and a fixed 1-2-3-4 cycle reads
## as a noticeable pattern at that speed where a random pick doesn't. Local
## to the barbell (its own AudioStreamPlayer, PumpSound), not the global sfx
## script — same reasoning as Body's jump/landing and Head's panic sounds.
@export var pump_sounds: Array[AudioStream] = [
	preload("res://assets/audio/sfx/jump/jump_1.wav"),
	preload("res://assets/audio/sfx/jump/jump_2.wav"),
	preload("res://assets/audio/sfx/jump/jump_3.wav"),
	preload("res://assets/audio/sfx/jump/jump_4.wav"),
]
@onready var _pump_sound: AudioStreamPlayer = $PumpSound

var _bodies: int = 0
var _held: bool = false
var _carrier: Node2D = null
var _carrier_visual: CanvasItem = null


func _ready() -> void:
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if visual != null:
		visual.play(&"alone")
	_set_occupied(false)


func _physics_process(_delta: float) -> void:
	if _carrier == null or not is_instance_valid(_carrier):
		return
	var offset: Vector2 = carry_offset
	if _carrier_visual is AnimatedSprite2D and (_carrier_visual as AnimatedSprite2D).flip_h:
		offset.x = -offset.x
		visual.flip_h = true
	else:
		visual.flip_h = false
	global_position = _carrier.global_position + offset


## One lift stroke — plays `lifting` from the start so a mash reads as a pump.
## Replaces the old ColorRect Tween. Called from the day on each `jump`.
func pump() -> void:
	if not _held or visual == null:
		return
	visual.play(&"lifting")
	visual.set_frame_and_progress(0, 0.0)
	_play_pump_sound()


## No-op if pump_sounds is empty. Random, not cycled — see the export's
## doc comment for why.
func _play_pump_sound() -> void:
	if pump_sounds.is_empty():
		return
	_pump_sound.stream = pump_sounds[randi() % pump_sounds.size()]
	_pump_sound.play()


func _pick_up() -> void:
	if _held or _bodies <= 0:
		return
	_held = true
	if prompt != null:
		prompt.visible = false
	# Deferred: _pick_up() runs from inside body_entered, and Godot blocks
	# changes to an Area2D's monitoring state during its own in/out signal
	# ("Function blocked during in/out signal" + an engine ERROR otherwise).
	set_deferred("monitoring", false)
	var body: Node2D = _find_body()
	if body != null:
		_carrier = body
		_carrier_visual = body.get_node_or_null("Visual") as CanvasItem
		if _carrier_visual != null:
			_carrier_visual.visible = false
		if visual != null:
			visual.play(&"with_body")
		set_physics_process(true)
	picked_up.emit()


func _find_body() -> Node2D:
	for other in get_overlapping_bodies():
		if other is CharacterBody2D:
			return other
	return get_tree().get_first_node_in_group("body") as Node2D


func _on_body_entered(body: Node2D) -> void:
	if _held or not body is CharacterBody2D:
		return
	_bodies += 1
	if _bodies == 1:
		_set_occupied(true)
		_pick_up()


func _on_body_exited(body: Node2D) -> void:
	if _held or not body is CharacterBody2D:
		return
	_bodies = maxi(_bodies - 1, 0)
	if _bodies == 0:
		_set_occupied(false)


func _set_occupied(occupied: bool) -> void:
	if prompt != null:
		prompt.visible = occupied
