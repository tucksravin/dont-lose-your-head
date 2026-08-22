class_name AnswerPad
extends Area2D
## A floor pad the body stands on, then confirms with the `interact` action
## (E / down — same binding as the reunion). Area2D so it doesn't push.
##
## Standing on it only lights the pad and shows the prompt. PuzzleChain still
## owns right/wrong; this node just emits `chosen(value)` on the press.
##
## Docs: https://docs.godotengine.org/en/stable/tutorials/inputs/input_examples.html

signal chosen(value: String)

@export var value: String = ""
@export var idle_color: Color = Color("645543")
@export var active_color: Color = Color("25c04b")

@onready var label: Label = $Label
@onready var visual: ColorRect = $Visual
@onready var prompt: Label = $Prompt

var _bodies: int = 0
var _enabled: bool = true


func _ready() -> void:
	add_to_group("answer_pad")
	set_process(false)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_label()
	_set_occupied(false)


func set_choice(next_value: String) -> void:
	value = next_value
	_refresh_label()


## Hide and ignore the pad (setup beat) or show it and accept interact (puzzle).
## Toggling `monitoring` deferred so we don't change physics mid-query; then
## recount overlaps because enabling does not re-fire `body_entered` for a
## body that is already standing here.
func set_enabled(on: bool) -> void:
	_enabled = on
	visible = on
	set_deferred("monitoring", on)
	if on:
		call_deferred("_sync_occupation")
	else:
		_bodies = 0
		_set_occupied(false)


func _refresh_label() -> void:
	if label != null:
		label.text = value


func _process(_delta: float) -> void:
	if _enabled and Input.is_action_just_pressed("interact"):
		chosen.emit(value)


func _sync_occupation() -> void:
	if not monitoring:
		return
	_bodies = 0
	for body in get_overlapping_bodies():
		if body is CharacterBody2D:
			_bodies += 1
	_set_occupied(_bodies > 0)


func _on_body_entered(body: Node2D) -> void:
	if not _enabled or not body is CharacterBody2D:
		return
	_bodies += 1
	if _bodies == 1:
		_set_occupied(true)


func _on_body_exited(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	_bodies = maxi(_bodies - 1, 0)
	if _bodies == 0:
		_set_occupied(false)


func _set_occupied(occupied: bool) -> void:
	set_process(_enabled and occupied)
	if visual != null:
		visual.color = active_color if occupied else idle_color
	if prompt != null:
		prompt.visible = occupied
