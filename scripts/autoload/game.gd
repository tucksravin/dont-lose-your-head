extends Node
## Game-wide state and scene flow (autoload: `Game`).
##
## This is the scene manager. It owns which day we're on and every move between
## intro / days / reunion. Nothing else should call change_scene_to_file().
##
## How a day ends:
##   WinConditions (in the day) sees the last need met → Events.day_completed
##     → this script calls head.release()  — the head rolls off screen, which is
##       the day's outro beat; there is no separate outro scene
##       → head.left_scene → next_day()
##
## The wait for `left_scene` is the point: without it the scene would swap on the
## same frame the last need was met and you'd never see the head leave.
##
## Autoloads are always in the tree, so this script must not assume a day is
## running. Everything below no-ops or falls through if there's no head.

## The days, in order (TASKS.md T5). Replace/extend as real days land.
##
## ORDERING CONSTRAINT while two flow systems coexist: days built on the older
## `WinConditions` node (day_template) advance through this list, because they
## emit `Events.day_completed` and _on_day_completed() below calls next_day().
## Days built on Sean's `DayManager` (platforming_day) do NOT — DayManager calls
## `Game.change_scene(its own next_scene)`, which defaults to the reunion. So a
## DayManager day has to sit LAST here, or it will skip everything after it.
## Unifying the two systems is an open team decision — see journals/tucker.md.
const DAY_SCENES: Array[String] = [
	"res://scenes/days/day_template.tscn",
	"res://scenes/days/day_panic.tscn",
	"res://scenes/days/platforming_day.tscn",
]

## Where we go after the last day.
const REUNION_SCENE: String = "res://scenes/reunion/reunion.tscn"

## Index into DAY_SCENES. -1 means "no day running" — which is also the case when
## you run a day scene directly from the editor to test it.
var current_day: int = -1


func _ready() -> void:
	Events.day_completed.connect(_on_day_completed)
	Events.day_failed.connect(_on_day_failed)


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


## Reload the current day from scratch — the fail path (DESIGN.md §2.1
## "Timer & fail"; instant restart is the default until §3.1 is decided).
func restart_day() -> void:
	get_tree().reload_current_scene()


## Every need in the day is met. Send the head off, and advance once it's gone.
func _on_day_completed() -> void:
	var head: Node = get_tree().get_first_node_in_group("head")
	if head == null:
		# No head in this scene (a test scene, say) — nothing to play out.
		next_day()
		return
	# CONNECT_ONE_SHOT disconnects after the first emit, so a head that somehow
	# re-emits can't advance the day twice.
	head.left_scene.connect(next_day, CONNECT_ONE_SHOT)
	head.release()


func _on_day_failed(_reason: String) -> void:
	restart_day()
