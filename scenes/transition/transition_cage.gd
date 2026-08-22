extends "res://scenes/transition/transition.gd"
## Transition fork: the head rolls down the slope, stops, and a cage drops on
## it → leads into day_panic (whose head opens `caged = true`).
##
## The worked example of the fork recipe in transition.gd: this file overrides
## exactly one method. The "cage" is not new art — it is the head's own
## `imprisoned` frames (head_keyed.png, Tucker's) on a second AnimatedSprite2D
## that falls from above and lands on the loose head, which then switches to
## the same loop. Two sprites so the bars can arrive separately from the skull.

## How far above the head the cage starts (px) and how long it takes to fall.
@export var cage_drop_height: float = 220.0
@export var cage_drop_time: float = 0.35

@onready var cage: AnimatedSprite2D = $Cage


func _play_arrival() -> void:
	# Park the cage above where the head stopped, then drop it.
	cage.global_position = head.global_position + Vector2(0, -cage_drop_height)
	cage.visible = true
	cage.play(&"imprisoned")
	var drop: Tween = create_tween()
	drop.tween_property(cage, "global_position", head.global_position, cage_drop_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await drop.finished
	# Landed: the head is now the caged head. Hide the falling cage and switch
	# the real head's loop so whatever follows sees one caged head, not two.
	cage.visible = false
	head.rotation = 0.0
	head.play(&"imprisoned")
	# A squash on impact, reusing the base bounce.
	await super()
