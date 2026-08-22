extends Node2D
## Sun — arcs across the top of the screen; doubles as the day timer.
## Position lerps from start to end while rising and falling in a sine arc.
## Emits `sunset` when it reaches the end — the day scene decides what that means.

@export var day_length: float = 30.0
@export var start_position: Vector2 = Vector2(20.0, 60.0)
@export var end_position: Vector2 = Vector2(620.0, 60.0)
@export var arc_height: float = 40.0

signal sunset

var _elapsed: float = 0.0
var _done: bool = false


func _ready() -> void:
	position = start_position


func _process(delta: float) -> void:
	if _done:
		return

	_elapsed += delta
	var t: float = clamp(_elapsed / day_length, 0.0, 1.0)
	position = start_position.lerp(end_position, t)
	position.y -= sin(t * PI) * arc_height

	if t >= 1.0:
		_done = true
		sunset.emit()
