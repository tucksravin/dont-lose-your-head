extends Node2D
## End card — the run's last screen, handed to us by the reunion's fade-out.
##
## Same trick as the title screen: this is the *real* body and head, not art.
## body.gd picks its animation off `velocity`, and in `is_scripted` mode it
## never calls move_and_slide() — so with `velocity` left at zero the guy just
## stands there, head on, facing the sun. `Head.attach()` is the same call the
## title and the reunion use to carry the skull.
##
## The reunion fades *to* black before changing scene, so this one fades *from*
## black — otherwise the end card pops in at full brightness.
##
## The kikis get one last say. head.tscn carries a `HeadThoughts` stream (a
## thought every 0.4 s, forever); this screen drops it the way the title does
## and spawns its own choreographed puff instead — a thick cloud packed round
## the skull at t=0 that drifts outward and fades, completely gone by
## `disperse_time`. One Tween per kiki, each one free'ing itself at the end,
## so nothing is left running behind the thank-you.
##
## `music_track` is read by the Music autoload (scripts/autoload/music.gd): it
## asks the scene root for that property first, and switching to a track that's
## already playing is a no-op — so the reunion's music carries straight through
## instead of stopping and restarting.
##
## The Replay button goes back to the *intro*, not the title: the title screen
## is the "press play" landing page and you have already pressed it. Restarting
## at the intro puts the run back at its first beat — and intro.gd sets
## `Game.wearing_glasses = true` on entry and ends by calling
## `Game.start_days()`, which resets `current_day`, so a second run starts from
## the same state as the first with nothing to reset here.
##
## Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html

## Music autoload reads this off the root. Same track as the reunion = no cut.
@export var music_track: StringName = &"reunion"
## Where the head sits on the body's neck, in body-local space — measured off
## the sprites, same value the title screen uses.
@export var head_mount: Vector2 = Vector2(0.0, -52.0)
## How long the fade in from the reunion's black takes.
@export var fade_in_duration: float = 1.2
## How many kikis are in the parting cloud. 44 packs the skull solid at 2x.
@export var cloud_count: int = 44
## Seconds from the thick cloud to nothing left on screen.
@export var disperse_time: float = 5.0
## Radius (px) of the cluster they start in — small = thick.
@export var cloud_radius: float = 22.0
## Where the cloud sits relative to the head centre (just above the 28 px box).
@export var cloud_offset: Vector2 = Vector2(0.0, -10.0)
## How far out they drift before they are gone (px).
@export var drift_min: float = 110.0
@export var drift_max: float = 260.0
## Share of the cloud that is a big_kiki rather than a lil one.
@export var big_kiki_share: float = 0.25
## Where the Replay button starts the run again. See the header.
@export_file("*.tscn") var replay_scene: String = "res://scenes/intro/intro.tscn"

@onready var _body: CharacterBody2D = $Body
@onready var _head: Head = $Head
@onready var _fade: ColorRect = $FadeOverlay/Fade
@onready var _replay: Button = $UI/Root/Replay

var _restarting: bool = false


func _ready() -> void:
	# is_scripted stops body.gd running gravity/input on it; velocity stays
	# zero, so its animation picker holds `idle`.
	_body.is_scripted = true
	_body.velocity = Vector2.ZERO
	_head.attach(_body, head_mount)
	create_tween().tween_property(_fade, "modulate:a", 0.0, fade_in_duration)
	_quiet_the_head()
	_burst_kikis()
	_replay.pressed.connect(_on_replay)
	# Focus means Enter/Space work as well as the mouse without this scene
	# reading input itself — a focused Button already handles `ui_accept`.
	_replay.grab_focus()


## Guarded like the title's play button: a double-click would otherwise fire
## two change_scene calls in the same frame.
func _on_replay() -> void:
	if _restarting:
		return
	_restarting = true
	Sfx.play(&"ui_confirm")
	Game.change_scene(replay_scene)


## Drop head.tscn's own endless thought stream — same call the title screen
## makes, and for the same reason: this screen wants to say something specific
## with the kikis, not trickle them forever. Hidden before the queue_free()
## because HeadThoughts spawns its first kiki in its own _ready() (children ready
## before parents) and a queue_free() only lands at the end of the frame, so
## without this one thought would be drawn for a frame before it went.
func _quiet_the_head() -> void:
	var thoughts: CanvasItem = _head.get_node_or_null("HeadThoughts") as CanvasItem
	if thoughts == null:
		return
	thoughts.visible = false
	thoughts.queue_free()


## The parting cloud: every kiki spawns at once in a tight cluster (that is the
## "thick"), then drifts outward and fades on its own Tween. Each one's travel
## time is rolled so it *ends* on or before `disperse_time` — the stagger is in
## when they finish, not when they start, so the cloud thins from the edges
## instead of everything vanishing on the same frame.
func _burst_kikis() -> void:
	for _i in cloud_count:
		var angle: float = randf() * TAU
		# sqrt keeps the random points evenly spread over the disc instead of
		# bunching them at the centre.
		var start: Vector2 = cloud_offset + Vector2.RIGHT.rotated(angle) * cloud_radius * sqrt(randf())
		var kind: StringName = &"big_kiki" if randf() < big_kiki_share else &"lil_kiki"
		var kiki: Kiki = Kiki.spawn(_head, kind, start)
		# Absolute z so the cloud reads over the body and the ground band.
		kiki.z_as_relative = false
		kiki.z_index = 10

		# Drift outward from the cluster centre, biased upward — thoughts leave
		# the way HeadThoughts sends them, they just leave in every direction now.
		var out: Vector2 = Vector2.RIGHT.rotated(angle) * randf_range(drift_min, drift_max)
		var dest: Vector2 = start + out + Vector2(0.0, -randf_range(20.0, 70.0))
		var travel: float = randf_range(disperse_time * 0.35, disperse_time)

		var tw: Tween = kiki.create_tween()
		tw.set_parallel(true)
		tw.tween_property(kiki, "position", dest, travel)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Linear on the alpha, not HeadThoughts' EASE_IN: over 0.8 s a late fade
		# reads as a puff, but over 5 s it holds every kiki at full opacity for
		# four of them and then pops the lot. Linear + the spread of `travel`
		# is what makes the cloud visibly thin the whole way down.
		tw.tween_property(kiki, "modulate:a", 0.0, travel)\
				.set_trans(Tween.TRANS_LINEAR)
		tw.chain().tween_callback(kiki.queue_free)
