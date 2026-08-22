extends Node2D
## Standalone sprite check — NOT part of the game flow. F6 to run.
## Shows the body walk at 2× and 1× over the proposed sky/ground colours, flipping direction every couple of seconds.

@export var flip_every: float = 1.5

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= flip_every:
		_t = 0.0
		for n in [$Body2x, $Body1x]:
			n.flip_h = not n.flip_h
