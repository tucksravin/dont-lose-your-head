extends Node2D
## Intro scene — the head runs off, you chase it. Nothing moves the body for
## you: the scene ends when YOU have run off the right edge after it (decided
## Sat evening, Tucker: "no scripting to make you follow, the scene shouldn't
## change till the player goes offscreen"). The head blob (HeadBlob,
## CharacterBody2D) is the one scripted thing — it runs right at head_speed
## and leaves; the body is the instanced body.tscn, player-driven by body.gd.
##
## Sun: the same timer every day has (scenes/sun/sun.tscn, found by its
## `sunset` signal the way DayManager finds it). Sunset before you've left =
## the intro restarts (Game.restart_day() reloads the current scene; in the
## intro current_day is -1, so that is all it does). Sfx's sunset warning
## wires itself to the Sun, like everywhere else.
##
## Camera2D is static (fixed at viewport centre) rather than parented to
## HeadBlob, so the head visibly runs off the right edge — the whole visual
## point of the shot. Day scenes are the same.
##
## TODO(cutscene): before the chase, a short Tween separation beat: skeleton
## stands still → intrusive thoughts appear → head "pops" off (scale bounce +
## rightward Tween) → chase. Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html

## How fast the head blob moves right (px/s).
@export var head_speed: float = 150.0
## Downward gravity for the head blob (px/s²). Body gravity is in body.gd.
@export var gravity: float = 980.0
## How far past the right edge the BODY must be before the intro is over (px).
## The body sprite is 32 px wide, so 24 means it is fully off screen.
@export var exit_margin: float = 24.0
## Pause after the body has left before the first day loads.
@export var exit_delay: float = 0.4
## NOT READ — Game.DAY_SCENES decides what comes next. Kept only so nothing that
## set it breaks; delete when nobody references it (TASKS N4).
@export var next_scene: String = "res://scenes/days/platforming_day.tscn"

@onready var head_blob: CharacterBody2D = $HeadBlob
@onready var body_blob: CharacterBody2D = $Body

var _exiting: bool = false


func _ready() -> void:
	# The Sun is found by its signal, not a hard path — same duck-type as
	# DayManager / Sfx use, so the node can be moved or renamed freely.
	for node in find_children("*", "Node2D", true, false):
		if node.has_signal("sunset"):
			node.connect("sunset", _on_sunset)
			break


func _physics_process(delta: float) -> void:
	_move_head(delta)
	_check_exit()


## Scripted rightward movement for the head blob. It keeps going off screen;
## nothing waits for it.
func _move_head(delta: float) -> void:
	head_blob.velocity.x = head_speed
	if head_blob.is_on_floor():
		head_blob.velocity.y = 0.0
	else:
		head_blob.velocity.y += gravity * delta
	head_blob.move_and_slide()


## The intro is over when the PLAYER has run off the right side.
## get_viewport_rect() is screen pixels (640×360); with the static camera at
## (320,180) that is world space 1-to-1.
func _check_exit() -> void:
	if _exiting:
		return
	var right_edge: float = get_viewport_rect().size.x
	if body_blob.global_position.x > right_edge + exit_margin:
		_exiting = true
		get_tree().create_timer(exit_delay).timeout.connect(_on_exit_delay)


## Sunset before you've left: the intro restarts, like a day that ran out of sun.
func _on_sunset() -> void:
	if _exiting:
		return
	Game.restart_day()


## Hand off to the day chain. Game owns the day order, so the intro doesn't name
## a specific scene — it just says "the intro is over, start the days".
func _on_exit_delay() -> void:
	Game.start_days()
