extends Node2D
## The opening, after the landing screen. A cutscene: the player has no input
## here (decided Sat, Tucker — "fully scripted until the head falls").
##
## Beats:
##   1. The guy walks in from the left and pulls up next to the crest of a slope.
##   2. A KikiCloud closes in and a PanicCounter fills — the same two nodes the
##      panic days use, so the opening teaches the mechanic before it costs
##      anything. The counter runs in its cutscene mode (`scripted_per_second`),
##      because here the meter is the *story*, not a response to the player.
##   3. At max the head pops off, lands on the crest, and rolls away down the
##      slope — and the moment it goes, **you get the controls** (Tucker, Sat:
##      "you should have to follow the head down in the initial scene"). The
##      scene ends when YOU have run off the right edge after it, not when the
##      head leaves; then Game.start_days() picks up in transition_bird, still
##      chasing.
##
## Why the panic ending is wired here and not left to the counter: maxing out
## normally calls DayManager.fail() (the game-over card). A cutscene has no
## DayManager, and "you lost the intro" is not a thing — so the counter's
## cutscene mode deliberately never fails, and this script watches
## `panic_changed` and runs the pop itself.
##
## The body is the real body.tscn, and it is only borrowed: for the walk-in it
## runs in `is_scripted` mode, where body.gd skips input but still animates off
## velocity and still emits landed/footsteps, and this script does what a
## player's fingers would — sets velocity, calls move_and_slide(). Clearing that
## flag when the head goes hands it straight back, mid-scene, with nothing to
## re-wire. The head rides on Head.attach() until it pops.
##
## The slope is the transition's slope (1 px down for every 3 across, ground
## `#006a3d`) with a flat shelf on the left to walk in on, so cutting from here
## to transition_bird reads as further down the same hill.
##
## Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html

## Walk-in speed (px/s). Slower than the player's 150 — he is strolling.
@export var walk_speed: float = 90.0
## World x he stops at. The crest is at 260; he pulls up short of it.
@export var mark_x: float = 200.0
## Gravity for the scripted walk-in. Same number body.gd uses.
@export var gravity: float = 980.0
## Where the head sits on the neck — measured like title.gd's, see there.
@export var head_mount: Vector2 = Vector2(0.0, -52.0)
## How far the head's sprite shakes at full panic (px). head.tscn's own default
## is 1.5, which is tuned for a caged head behind bars; loose it needs more.
@export var head_jitter: float = 3.0
## Beat after he stops, before the thoughts start arriving.
@export var settle_time: float = 0.7
## The pop: up-and-over to `pop_peak`, then down onto `pop_landing`.
@export var pop_up_time: float = 0.28
@export var pop_fall_time: float = 0.34
@export var pop_peak: Vector2 = Vector2(232.0, 112.0)
## Landing point — 16 px above the crest, which is where a centred 32 px head
## rests on the ground. Roll from here and it rides the slope exactly.
@export var pop_landing: Vector2 = Vector2(260.0, 184.0)
## Seconds for the kikis to clear out once the head is off.
@export var kiki_fade_time: float = 0.5
## How fast the head leaves, and down which line. (3, 1) IS the slope, so the
## head stays exactly 16 px above the ground the whole way down.
@export var roll_speed: float = 220.0
@export var roll_direction: Vector2 = Vector2(3.0, 1.0)
## Chase: floor snap for the body once the player has it (px). The same number
## transition.gd uses — downhill at run speed the default 1 px lets it skip off
## the slope instead of following it.
@export var chase_floor_snap: float = 8.0
## How far past the right edge the BODY must be for the scene to be over. The
## body sprite is 32 px wide, so 24 means it is fully gone.
@export var exit_margin: float = 24.0
## Pause after the body has left, before the fade.
@export var exit_delay: float = 0.4
@export var fade_duration: float = 0.5

@onready var body: CharacterBody2D = $Body
@onready var head: Head = $Head
@onready var counter: PanicCounter = $PanicCounter
@onready var cloud: Node2D = $KikiCloud
@onready var fade: ColorRect = $FadeOverlay/Fade
@onready var instruction: Label = $Instruction

var _walking: bool = true
var _popped: bool = false
var _chasing: bool = false
var _exiting: bool = false


func _ready() -> void:
	# A run always starts with the glasses on. The landing screen sets this too.
	Game.wearing_glasses = true
	body.is_scripted = true
	head.attach(body, head_mount)
	# head.gd only runs its shake for a caged head (`set_process(caged)` in its
	# _ready). This head is loose, but it is the most panicked it will ever be,
	# so switch the shake back on by hand.
	head.jitter_px = head_jitter
	head.set_process(true)
	instruction.visible = false
	# The meter holds at 0 until he has arrived — the thoughts turn up when he
	# stops, not while he is walking.
	counter.set_physics_process(false)
	counter.panic_changed.connect(_on_panic_changed)


func _physics_process(delta: float) -> void:
	if _walking:
		if body.global_position.x < mark_x:
			body.velocity.x = walk_speed
		else:
			body.velocity.x = 0.0
			_walking = false
			_arrive()
		if not body.is_on_floor():
			body.velocity.y += gravity * delta
		body.move_and_slide()
		return
	if _chasing and not _exiting:
		_check_exit()


## He is at the mark. Beat, then let the thoughts in.
func _arrive() -> void:
	await get_tree().create_timer(settle_time).timeout
	counter.set_physics_process(true)


## The meter reports whole numbers; the top of it is the cue for the pop.
func _on_panic_changed(value: int) -> void:
	if _popped or float(value) < counter.max_panic:
		return
	_popped = true
	_pop_head()


## The head comes off: a hop up and over, a landing on the crest, then it rolls
## away down the slope under head.gd's own release().
func _pop_head() -> void:
	counter.set_physics_process(false)
	head.detach()
	head.set_process(false) # done shaking — it is rolling now
	# Drop the panic tint. PanicCounter darkens the head toward Colors.DARK_GREEN
	# as the meter fills, which is the right cue while the head is up against the
	# sky — but DARK_GREEN *is* the ground colour, so a tinted head rolling down
	# the hill is invisible (measured: it vanished into the slope). The snap back
	# to bone also reads as the panic breaking.
	#
	# Deferred, and it has to be: we are inside `panic_changed`, which
	# PanicCounter._apply() emits BEFORE it pushes the tint to the head — so a
	# plain call here gets overwritten one line later, and with the counter's
	# physics process now off, nothing would ever repaint it. call_deferred puts
	# us after _apply() has finished.
	head.set_panic_ratio.call_deferred(0.0)
	head.z_index = 1
	Sfx.play(&"head_roll")
	# TWEEN_PROCESS_PHYSICS: the head is a (frozen) RigidBody2D, so its
	# transform belongs to the physics step — animating it on the idle frame
	# gives a visible stutter against the body next to it.
	var arc: Tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	arc.tween_property(head, "global_position", pop_peak, pop_up_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.parallel().tween_property(head, "rotation", deg_to_rad(-50.0), pop_up_time)
	arc.parallel().tween_property(cloud, "modulate:a", 0.0, kiki_fade_time)
	arc.tween_property(head, "global_position", pop_landing, pop_fall_time) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	arc.parallel().tween_property(head, "rotation", 0.0, pop_fall_time)
	await arc.finished
	# head.gd already knows how to leave: straight line + spin + left_scene when
	# it clears the edge. Point it down the slope and let it go.
	head.exit_direction = roll_direction
	head.exit_speed = roll_speed
	head.release()
	_hand_over()


## The head is gone: give the player the body and tell them what to do with it.
## Clearing `is_scripted` is the whole handover — body.gd reads input again from
## the next physics tick, and this script stops calling move_and_slide().
func _hand_over() -> void:
	body.floor_snap_length = chase_floor_snap
	body.is_scripted = false
	instruction.visible = true
	_chasing = true


## Over when the PLAYER has left, not when the head did. get_viewport_rect() is
## screen pixels (640×360); the camera is fixed at the centre, so screen and
## world line up 1-to-1 here.
func _check_exit() -> void:
	if body.global_position.x <= get_viewport_rect().size.x + exit_margin:
		return
	_exiting = true
	_leave()


func _leave() -> void:
	await get_tree().create_timer(exit_delay).timeout
	var out: Tween = create_tween()
	out.tween_property(fade, "modulate:a", 1.0, fade_duration)
	await out.finished
	Game.start_days()
