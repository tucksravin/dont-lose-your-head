extends Node
class_name PanicCounter
## Tracks how "panicked" the day is — a day_panic-local fail condition
## alongside the sun timer. Adds panic every physics frame the body has
## nonzero velocity (walking counts; so does falling); once it reaches
## max_panic, the day fails via Events.day_failed, the same escape hatch
## the sun timer uses.
##
## Finds the body by group rather than a wired NodePath — the same way Game
## finds "the" head — so dropping this into a day needs no per-instance setup.

## How much panic each physics frame of movement adds.
@export var panic_per_move: int = 1
## Panic value that fails the day.
@export var max_panic: int = 100

## Emitted whenever `value` changes — the panic display listens to this.
signal panic_changed(value: int)

var value: int = 0

var _body: CharacterBody2D
var _failed: bool = false


func _ready() -> void:
	add_to_group("panic_counter")
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D


func _physics_process(_delta: float) -> void:
	if _failed or _body == null:
		return
	if _body.velocity != Vector2.ZERO:
		_add(panic_per_move)


func _add(amount: int) -> void:
	print("Hi I'm adding")
	value = mini(value + amount, max_panic)
	panic_changed.emit(value)
	if value >= max_panic:
		_failed = true
		Events.day_failed.emit("panic")
