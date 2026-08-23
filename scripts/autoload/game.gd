extends Node
## Game-wide state and scene flow (autoload: `Game`).
##
## This is the playlist. It owns which day we're on and every move between
## intro / days / reunion. Nothing else should call change_scene_to_file().
##
## How a day ends (DESIGN.md §2.2): DayManager owns the *when*. On win it
## releases the head, waits for left_scene, then calls next_day() — which
## walks this list. On fail it shows the game-over card; Retry reloads.
## Game does not listen to Events.day_completed / day_failed.
##
## Autoloads are always in the tree, so this script must not assume a day is
## running. Everything below no-ops or falls through if there's no head.

## The days, in order (TASKS.md T5). Replace/extend as real days land.
##
## Transitions live in this same list, right BEFORE the day they lead into: a
## transition scene (scenes/transition/) ends by calling next_day() itself, so
## the run is simply "the scenes, in order". See transition.gd for how to make one.
##
## Glasses story: intro wears them; still-panic is caged-with-glasses; the
## head falls out of the tree / off the cliff into the cage transition;
## hanging panic keeps them; glasses transition knocks them off; Velma
## finds them. Order: still → cage transition → hanging panic.
const DAY_SCENES: Array[String] = [
	"res://scenes/days/day_panic_still.tscn",
	"res://scenes/transition/transition_cage.tscn",
	"res://scenes/days/day_panic.tscn",
	"res://scenes/days/day_workout.tscn",
	"res://scenes/transition/transition_glasses.tscn",
	"res://scenes/days/day_velma.tscn",
	"res://scenes/days/day_lockdown.tscn",
	"res://scenes/days/day_mirror.tscn",
]

## Where we go after the last day.
const REUNION_SCENE: String = "res://scenes/reunion/reunion.tscn"

## Index into DAY_SCENES. -1 means "no day running" — which is also the case when
## you run a day scene directly from the editor to test it.
var current_day: int = -1
## Persists across scenes. Intro starts true; glasses transition sets false;
## Velma sets true again on delivery. Head.refresh_face() reads this.
var wearing_glasses: bool = true


## Load a scene by path. Thin wrapper so call sites don't reach for the tree directly.
func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


## Start the run at the first day. The intro calls this when it finishes.
func start_days() -> void:
	go_to(0)


## Load day `index`, or the reunion if we're past the end.
func go_to(index: int) -> void:
	if index < 0 or index >= DAY_SCENES.size():
		current_day = -1
		change_scene(REUNION_SCENE)
		return
	current_day = index
	change_scene(DAY_SCENES[index])


## Advance one scene in the run. From -1 (a scene run directly in the editor
## with F6) it first looks up where the current scene sits in DAY_SCENES, so
## testing a single day still goes on to the *right* next day. A scene that
## isn't in the list at all starts the run from the top.
func next_day() -> void:
	if current_day < 0:
		var scene: Node = get_tree().current_scene
		if scene != null:
			current_day = DAY_SCENES.find(scene.scene_file_path)
	go_to(current_day + 1)


## Reload the current day from scratch. Retry on the game-over card does this
## itself (it also has to unpause); keep this for Dev F5 and a DayManager
## that has no overlay assigned.
func restart_day() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
