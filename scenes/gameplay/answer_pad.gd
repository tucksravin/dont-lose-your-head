class_name AnswerPad
extends Area2D
## One answer plate in Lockdown's math problem. **You choose it by landing on
## it** — no key, and walking over it is deliberately safe (Tucker, Sat).
##
## Nearly all the work lives on the `$Visual` FloorPlate
## (scenes/gameplay/floor_plate.gd) — the same floor button the panic day uses.
## It squashes to `mid` under a body that walks over it, slams flat and emits
## `stomped` when the body LANDS on it, and rises when the body steps off. This
## script turns a stomp into an answer and nothing else; PuzzleChain still owns
## right and wrong.
##
## Why landing and not touching: the plates sit on the floor the body walks
## along and a wrong answer fails the day — the body finishes the setup beat to
## the RIGHT of all three, so a walk to the plate you want crosses the ones you
## don't. Landing is a deliberate act, and it is what makes the plates being
## small enough to jump over (32x8) worth doing.
##
## The node stays an Area2D so PuzzleChain and the day can keep addressing it
## the way they always have (group `answer_pad`), and so its shape still
## documents the plate's footprint in the editor.

signal chosen(value: String)

@export var value: String = ""

@onready var label: Label = $Label
## The plate: button.png (Tucker's), a FloorPlate.
@onready var visual: FloorPlate = $Visual

var _enabled: bool = true


func _ready() -> void:
	add_to_group("answer_pad")
	visual.stomped.connect(_on_stomped)
	visual.set_live(_enabled)
	_refresh_label()


func set_choice(next_value: String) -> void:
	value = next_value
	_refresh_label()


## Hide and ignore the plate (the setup beat) or show it and take landings.
func set_enabled(on: bool) -> void:
	_enabled = on
	visible = on
	if visual != null:
		visual.set_live(on)


func _refresh_label() -> void:
	if label != null:
		label.text = value


## The body landed on this plate — that is the answer.
func _on_stomped(_impact: float) -> void:
	if _enabled:
		chosen.emit(value)
