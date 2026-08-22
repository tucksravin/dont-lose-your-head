class_name Head
extends RigidBody2D
## The head — scripted, not simulated (DESIGN.md §2.1).
##
## In a day scene the head opens **already at its stuck position** and does
## nothing at all until the day's win conditions are satisfied and something
## calls release() (TASKS.md T4). It then travels off screen and reports
## left_scene, which is the day's cue to advance (TASKS.md T5).
##
## Why a frozen RigidBody2D instead of a plain Node2D: keeping the node type
## means real rolling physics is one line away — stop freezing it — if the
## scripted version ever feels lifeless. See the "Reversible" note in
## DESIGN.md §2.1.
##
## freeze_mode KINEMATIC (rather than the default STATIC) is the mode meant for
## "I move this body from code": it still reports collisions and can push other
## bodies, where STATIC expects the body to never move at all.
## Docs: https://docs.godotengine.org/en/stable/classes/class_rigidbody2d.html

## Emitted the instant release() is called — the head has started leaving.
signal released
## Emitted once the head is fully off screen. The day listens for this to advance.
signal left_scene

## How fast the head travels once released (px/s).
@export var exit_speed: float = 180.0
## Which way the head leaves. Right by default; a day can point it anywhere.
@export var exit_direction: Vector2 = Vector2.RIGHT
## Pixels past the viewport edge before left_scene fires, so it is fully hidden.
@export var exit_margin: float = 64.0

var _leaving: bool = false


func _ready() -> void:
	# Scripted, not simulated: hold the body frozen for its whole life.
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	freeze = true
	# Nothing to do until release() — skip the per-frame callback entirely
	# rather than running an early-return every physics tick.
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	global_position += exit_direction.normalized() * exit_speed * delta
	if _is_off_screen():
		set_physics_process(false)
		left_scene.emit()


## Let the head go. The day calls this once every WinCondition is satisfied.
## Safe to call more than once — repeat calls are ignored.
func release() -> void:
	if _leaving:
		return
	_leaving = true
	released.emit()
	set_physics_process(true)


## True once the head has cleared the visible rect by exit_margin.
##
## get_viewport_rect() is screen space, (0,0)→(640,360). Days use a fixed camera
## centred on the screen (DESIGN.md §2.1 "Fixed camera per scene"), so world and
## screen coordinates line up 1-to-1 and this comparison is valid. It would need
## revisiting if a scene ever scrolled.
func _is_off_screen() -> bool:
	var view: Vector2 = get_viewport_rect().size
	return (global_position.x > view.x + exit_margin
			or global_position.x < -exit_margin
			or global_position.y > view.y + exit_margin
			or global_position.y < -exit_margin)
