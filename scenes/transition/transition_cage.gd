extends "res://scenes/transition/transition.gd"
## Transition fork: the head sits at the top of the slope, the body has almost
## caught up to it, and a cage drops on it — the knock is what sends the caged
## head rolling off down the slope, ALL THE WAY OFF THE SCREEN (Tucker, Sat:
## "when the head is caged, have it roll all the way off the screen") → leads
## into day_panic (whose head opens `caged = true`). Decided Sat (Tucker): "the
## cage should initiate the head's roll; the head isn't running away from the
## body".
##
## Off-screen roll = three overrides on the inherited scene, no code: HeadPath's
## curve runs to x=720 (past the right edge; the ground polygon goes to 740),
## roll_time 1.6 (≈300 px/s, still faster than the body), brake_ratio 1.0 (no
## visible slow-down — it stops off screen). The base's end condition is
## unchanged and now means "the body has run off after it" (within
## arrive_distance 40 of x=720 = fully off the 640-wide screen), then the fade.
##
## The worked example of the fork recipe in transition.gd: this file overrides
## exactly one method. The "cage" is not new art — it is the head's own
## `imprisoned` frames (head_keyed.png, Tucker's) on a second AnimatedSprite2D
## that falls from above and lands on the loose head, which then switches to
## the same loop (and tumbles off in it — the base spins whole turns, so it
## comes to rest bars-upright). Two sprites so the bars can arrive separately
## from the skull.

## How far above the head the cage starts (px) and how long it takes to fall.
@export var cage_drop_height: float = 220.0
@export var cage_drop_time: float = 0.35

@onready var cage: AnimatedSprite2D = $Cage


func _play_arrival() -> void:
	# Park the cage above the resting head, then drop it.
	cage.global_position = head.global_position + Vector2(0, -cage_drop_height)
	cage.visible = true
	cage.play(&"imprisoned")
	var drop: Tween = create_tween()
	drop.tween_property(cage, "global_position", head.global_position, cage_drop_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await drop.finished
	# Landed: the head is now the caged head. Hide the falling cage and switch
	# the real head's loop so the roll that follows is one caged head, not two.
	cage.visible = false
	head.rotation = 0.0
	head.play(&"imprisoned")
	# The impact squash from the base; when it returns, the head rolls.
	await super()
