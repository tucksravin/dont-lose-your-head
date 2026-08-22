extends Node2D
## Sun — arcs across the top of the screen; doubles as the day timer.
## Position lerps from start to end while rising and falling in a sine arc.
## Emits `sunset` when it reaches the end — the day scene decides what that means.

@export var day_length: float = 30.0
@export var start_position: Vector2 = Vector2(20.0, 60.0)
@export var end_position: Vector2 = Vector2(620.0, 60.0)
@export var arc_height: float = 40.0
## Subtle life: the disc swells ± this much scale on a slow cycle (0 = off).
@export var pulse_amount: float = 0.08
@export var pulse_period: float = 1.6

signal sunset

var _elapsed: float = 0.0
var _done: bool = false

@onready var _visual: Node2D = get_node_or_null("Visual")
@onready var _visual_scale: Vector2 = _visual.scale if _visual != null else Vector2.ONE


func _ready() -> void:
	position = start_position


## How far through the day we are, 0 → 1. The sky (sky_drift.gd) and anything
## else that wants "how late is it" reads this instead of poking _elapsed.
func progress() -> float:
	return clampf(_elapsed / day_length, 0.0, 1.0)


func _process(delta: float) -> void:
	if _done:
		return

	_elapsed += delta
	var t: float = clamp(_elapsed / day_length, 0.0, 1.0)
	position = start_position.lerp(end_position, t)
	position.y -= sin(t * PI) * arc_height
	if _visual != null and pulse_amount > 0.0:
		_visual.scale = _visual_scale * (1.0 + pulse_amount * sin(_elapsed / pulse_period * TAU))

	if t >= 1.0:
		_done = true
		sunset.emit()
