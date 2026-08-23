extends Node2D
## Landing screen — the first thing the game boots into (project.godot
## run/main_scene). One button starts the run; there is no menu.
##
## "Let the Intrusive Thoughts In" is the click-to-play (Tucker, Sat): the
## screen states the theme instead of explaining controls.
##
## The guy walking in place is the *real* body and head, not a mock-up. body.gd
## picks its animation off `velocity`, not off input, and in `is_scripted` mode
## it never calls move_and_slide() — so setting `velocity.x` here makes it play
## `walk` forever without going anywhere. That is also why there is no floor
## collider: `is_on_floor()` stays false, which keeps body.gd's footstep loop
## quiet on a menu screen. The head rides along through `Head.attach()`, the
## same call the lockdown day uses to carry it.
##
## Docs: https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html

## Fake walk speed. Only read by body.gd's animation picker (anything > 1
## plays `walk`); nothing moves, so the number is not a distance.
@export var walk_velocity: float = 60.0
## Where the head sits on the body's neck, in the body's local space. Measured
## off the sprites: the walk frames' neck stub tops out at body-local y −40
## (−38 on the other two, the bob), and the head's jaw is 14 px below its own
## origin — so −52 sits the jaw on the neck at the bottom of the bob and lets it sink
## 2 px at the top of it — the head never floats, it rides.
@export var head_mount: Vector2 = Vector2(0.0, -52.0)
## Scene the button starts. The intro then hands off to Game.start_days().
@export_file("*.tscn") var play_scene: String = "res://scenes/intro/intro.tscn"

@onready var _body: CharacterBody2D = $Body
@onready var _head: Head = $Head
@onready var _play: Button = $UI/Root/Play

var _starting: bool = false


func _ready() -> void:
	# A run always begins with the glasses on; the title shows the guy as the
	# player will first meet him. intro.gd sets this too — harmless twice.
	Game.wearing_glasses = true
	_body.is_scripted = true
	_body.velocity.x = walk_velocity
	_head.attach(_body, head_mount)
	_play.pressed.connect(_on_play)
	# Focus means Enter/Space work as well as the mouse, without this scene
	# reading any input itself — Button already handles `ui_accept` when focused.
	_play.grab_focus()


func _on_play() -> void:
	if _starting:
		return
	_starting = true
	Sfx.play(&"ui_confirm")
	Game.change_scene(play_scene)
