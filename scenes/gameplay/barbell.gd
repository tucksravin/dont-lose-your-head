class_name Barbell
extends Area2D
## Floor barbell: **walking into it picks it up** — no key (Tucker, Sat:
## "when we hit a trigger it just happens"). Area2D so it doesn't push. After
## pickup it follows the body (scripted offset) — not Head.attach, which is
## for the skull.
##
## Docs: https://docs.godotengine.org/en/stable/tutorials/physics/using_area_2d.html

signal picked_up

@export var carry_offset: Vector2 = Vector2(0.0, -36.0)
@export var pump_height: float = 14.0
@export var pump_time: float = 0.07

@onready var prompt: Label = $Prompt

var _bodies: int = 0
var _held: bool = false
var _carrier: Node2D = null
var _pump_y: float = 0.0
var _pump_tween: Tween


func _ready() -> void:
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_set_occupied(false)


func _physics_process(_delta: float) -> void:
	if _carrier == null or not is_instance_valid(_carrier):
		return
	var offset: Vector2 = carry_offset
	var sprite: AnimatedSprite2D = _carrier.get_node_or_null("Visual") as AnimatedSprite2D
	if sprite != null and sprite.flip_h:
		offset.x = -offset.x
	global_position = _carrier.global_position + offset + Vector2(0.0, _pump_y)


## One lift stroke. Called from the day on each mash. Restarts if already pumping
## so a fast mash still reads as up-down. Tween — Godot's one-shot interpolator.
func pump() -> void:
	if not _held:
		return
	if _pump_tween != null and _pump_tween.is_valid():
		_pump_tween.kill()
	_pump_y = -pump_height
	_pump_tween = create_tween()
	_pump_tween.tween_property(self, "_pump_y", 0.0, pump_time)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)


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
