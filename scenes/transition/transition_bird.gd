extends "res://scenes/transition/transition.gd"
## Transition fork: the opening's chase. The intro has already knocked the head
## loose — it popped off and rolled over the crest — so there is no situation to
## play here. You get the controls back, chase it down the hill, and the moment
## you have finally caught up a **bird** drops in, takes it, and flies off to the
## right with it (Tucker, Sat: "use the controls to chase the head down the hill
## until a bird grabs the head and flies off to the right with it"). That is what
## puts the head up a tree on a cliff edge for day_panic_still.
##
## This is the worked example of the base's SECOND hook. `_play_arrival` is
## overridden to do nothing (no cage, no squash — nothing befalls the head, it
## just goes as you close on it) and all of the beat lives in `_play_exit`,
## which the base calls once the body has reached the stopped head.
##
## Carrying the head: `reparent` onto the bird, the same trick
## transition_glasses uses to get the head off the PathFollow2D. It keeps the
## sprite's global transform, so the head does not jump at the grab, and after
## it the bird's own tween carries both. Docs:
## https://docs.godotengine.org/en/stable/classes/class_node.html#class-node-method-reparent

## Where the bird comes in from, relative to the head it is coming for.
## Off the left edge and high, so it crosses the frame on its way down.
@export var swoop_from: Vector2 = Vector2(-620.0, -210.0)
## Seconds for the dive in. Eased IN — it is falling out of the sky.
@export var swoop_time: float = 0.85
## Where the bird sits relative to the head while carrying it: the head hangs
## from underneath, so the bird's own body clears it.
@export var carry_offset: Vector2 = Vector2(0.0, -30.0)
## Beat at the bottom of the dive, before the lift — the grab reads as a moment.
@export var grab_pause: float = 0.18
## Where it leaves to, relative to where it grabbed. Off the right edge and up.
@export var exit_to: Vector2 = Vector2(320.0, -330.0)
@export var exit_time: float = 1.1
## How far the carried head lolls over as it goes (degrees).
@export var carry_tilt: float = -22.0

@onready var bird: AnimatedSprite2D = $Bird


## Nothing befalls this head — the intro already did. The base's squash would
## read as an impact that isn't there, so this returns straight away and the
## head rolls the moment the body closes in.
func _play_arrival() -> void:
	await get_tree().process_frame


## The bird: in from off-screen left, down onto the resting head, a beat, then
## up and away to the right carrying it.
func _play_exit() -> void:
	var grab_at: Vector2 = head.global_position + carry_offset
	bird.global_position = head.global_position + swoop_from
	bird.visible = true
	bird.play(&"fly")
	var dive: Tween = create_tween()
	dive.tween_property(bird, "global_position", grab_at, swoop_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await dive.finished
	# Got it. reparent keeps the head exactly where it is on screen and hands
	# the job of moving it to the bird — the PathFollow2D is done with it.
	head.reparent(bird)
	# Behind the bird, so the claws read as over the skull rather than under it.
	head.z_index = -1
	await get_tree().create_timer(grab_pause).timeout
	var away: Tween = create_tween()
	away.tween_property(bird, "global_position", grab_at + exit_to, exit_time) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	away.parallel().tween_property(head, "rotation", deg_to_rad(carry_tilt), exit_time) \
			.set_trans(Tween.TRANS_SINE)
	await away.finished
