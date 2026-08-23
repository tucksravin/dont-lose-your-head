extends "res://scenes/transition/transition.gd"
## Transition fork: the head sits at the top of the slope, the body has almost
## caught up to it, and a cage drops on it — the knock is what sends the caged
## head rolling off down the slope, ALL THE WAY OFF THE SCREEN (Tucker, Sat:
## "when the head is caged, have it roll all the way off the screen") → leads
## into the hanging day_panic (whose head opens `caged = true`). Comes after
## day_panic_still, whose head just tipped off a cliff. Decided Sat (Tucker): "the
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
## from the skull. Glasses stay on. They come off in transition_glasses, after panic.

## How far above the head the cage starts (px) and how long it takes to fall.
@export var cage_drop_height: float = 220.0
@export var cage_drop_time: float = 0.35
## The impact, played the instant the cage reaches the head. Local to this
## scene (its own AudioStreamPlayer, CageSound) rather than the global Sfx
## script — same reasoning as Body's jump/landing and Head's panic sounds:
## the node that knows the moment plays its own sound.
@export var cage_land_sound: AudioStream = preload("res://assets/audio/sfx/cage/cage_2.wav")

@onready var cage: AnimatedSprite2D = $Cage
@onready var _cage_sound: AudioStreamPlayer = $CageSound
@onready var _cage_rolling_sound: AudioStreamPlayer = $CageRollingSound


func _play_arrival() -> void:
	# Park the cage above the resting head, then drop it.
	cage.global_position = head.global_position + Vector2(0, -cage_drop_height)
	cage.visible = true
	var cage_anim: StringName = &"imprisoned"
	if Game.wearing_glasses and cage.sprite_frames != null \
			and cage.sprite_frames.has_animation(&"imprisoned_glasses"):
		cage_anim = &"imprisoned_glasses"
	cage.play(cage_anim)
	var drop: Tween = create_tween()
	drop.tween_property(cage, "global_position", head.global_position, cage_drop_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await drop.finished
	# Landed: the head is now the caged head. Hide the falling cage and switch
	# the real head's loop so the roll that follows is one caged head, not two.
	if cage_land_sound != null:
		_cage_sound.stream = cage_land_sound
		_cage_sound.play()
	cage.visible = false
	head.rotation = 0.0
	head.play(cage_anim)
	print("PLAY ROLLING")
	print(_cage_rolling_sound.stream)
	await _cage_sound.finished
	_cage_rolling_sound.play()
	# The impact squash from the base; when it returns, the head rolls.
	await super()
	_cage_rolling_sound.stop()
