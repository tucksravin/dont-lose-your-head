extends Node
## Dev keys + debug overlay (autoload: `Dev`). DEBUG BUILDS ONLY.
##
## Everything here is gated on OS.is_debug_build(): that is true in the editor
## and for `--headless` runs, false in the exported web build — so the keys and
## the overlay simply do not exist in what we ship. No per-day wiring: it finds
## the current day's parts by group / type, the same way Game does.
##
## Keys (F-keys so nothing clashes with gameplay; registered at runtime as
## `debug_*` input actions so project.godot's input map stays clean):
##   F1  satisfy the BODY need      F2  satisfy the MIND need     F3  satisfy all
##   F4  fail the day               F5  restart the day
##   F6  previous scene in the run  F7  next scene in the run     F8  jump to the reunion
##   F9  toggle the overlay         F10 toggle slow motion (0.25×)
## The overlay shows: scene, day index, each need ✓/✗, sun %, panic, body
## position / velocity / on-floor, FPS, time scale.
##
## Godot notes: InputMap.add_action() at runtime is how you get a named action
## without touching Project Settings — fine for dev-only keys, not for gameplay
## ones (those belong in project.godot so everyone sees them). Engine.time_scale
## slows the whole tree (timers, tweens, physics) — good for eyeballing an
## animation, so it's here rather than in any scene.

const KEYS: Dictionary = {
	"debug_satisfy_body": KEY_F1,
	"debug_satisfy_mind": KEY_F2,
	"debug_satisfy_all": KEY_F3,
	"debug_fail": KEY_F4,
	"debug_restart": KEY_F5,
	"debug_prev": KEY_F6,
	"debug_next": KEY_F7,
	"debug_reunion": KEY_F8,
	"debug_overlay": KEY_F9,
	"debug_slowmo": KEY_F10,
}

var _overlay: CanvasLayer
var _label: Label
var _slow: bool = false


func _ready() -> void:
	if not OS.is_debug_build():
		set_process(false)
		set_process_unhandled_input(false)
		return
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var ev: InputEventKey = InputEventKey.new()
			ev.physical_keycode = KEYS[action]
			InputMap.action_add_event(action, ev)
	_build_overlay()
	print("Dev keys: F1 body need · F2 mind need · F3 all · F4 fail · F5 restart · F6/F7 prev/next · F8 reunion · F9 overlay · F10 slow-mo")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_satisfy_body"):
		satisfy("body")
	elif event.is_action_pressed("debug_satisfy_mind"):
		satisfy("mind")
	elif event.is_action_pressed("debug_satisfy_all"):
		satisfy("")
	elif event.is_action_pressed("debug_fail"):
		fail()
	elif event.is_action_pressed("debug_restart"):
		restart()
	elif event.is_action_pressed("debug_prev"):
		step(-1)
	elif event.is_action_pressed("debug_next"):
		step(1)
	elif event.is_action_pressed("debug_reunion"):
		Game.change_scene(Game.REUNION_SCENE)
	elif event.is_action_pressed("debug_overlay"):
		_overlay.visible = not _overlay.visible
	elif event.is_action_pressed("debug_slowmo"):
		_slow = not _slow
		Engine.time_scale = 0.25 if _slow else 1.0


## Satisfy every WinCondition in the current scene whose key matches
## (empty key = all of them). Works for both flow systems because both listen
## to WinCondition.satisfied.
func satisfy(key: String) -> void:
	for c in _conditions():
		if key.is_empty() or str(c.get("key")) == key:
			c.call("satisfy")


## Fail the current day the way its own system would: DayManager.fail() if the
## scene has one (shows the game-over card), else Events.day_failed (restart).
func fail() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var managers: Array[Node] = scene.find_children("*", "DayManager", true, false)
	if not managers.is_empty():
		managers[0].call("fail", "dev")
	else:
		Events.day_failed.emit("dev")


func restart() -> void:
	get_tree().paused = false  # a game-over card may have paused us
	Game.restart_day()


## Move ±1 through Game.DAY_SCENES. If the current scene was opened straight
## from the editor (Game.current_day == -1), work out where it sits first.
func step(delta: int) -> void:
	get_tree().paused = false
	var index: int = Game.current_day
	if index < 0 and get_tree().current_scene != null:
		index = Game.DAY_SCENES.find(get_tree().current_scene.scene_file_path)
	var target: int = index + delta
	if target < 0:
		target = 0
	if target >= Game.DAY_SCENES.size():
		Game.change_scene(Game.REUNION_SCENE)
		Game.current_day = -1
		return
	Game.go_to(target)


func _process(_delta: float) -> void:
	if _overlay == null or not _overlay.visible:
		return
	_label.text = _overlay_text()


func _conditions() -> Array[Node]:
	var out: Array[Node] = []
	var scene: Node = get_tree().current_scene
	if scene == null:
		return out
	for n in scene.find_children("*", "Node", true, false):
		if n.has_method("satisfy") and "key" in n and "is_satisfied" in n:
			out.append(n)
	return out


func _overlay_text() -> String:
	var scene: Node = get_tree().current_scene
	var lines: PackedStringArray = []
	lines.append("%s   day %d/%d   %d fps   ×%.2f" % [
			scene.scene_file_path.get_file() if scene != null else "(no scene)",
			Game.current_day, Game.DAY_SCENES.size(), Engine.get_frames_per_second(), Engine.time_scale])
	var needs: PackedStringArray = []
	for c in _conditions():
		needs.append("%s %s" % [c.get("key"), "✓" if bool(c.get("is_satisfied")) else "✗"])
	if not needs.is_empty():
		lines.append("needs: " + " · ".join(needs))
	if scene != null:
		for n in scene.find_children("*", "Node2D", true, false):
			if "day_length" in n and n.has_signal("sunset"):
				lines.append("sun: %d%%" % int(100.0 * float(n.get("_elapsed")) / maxf(float(n.get("day_length")), 0.001)))
				break
		var panic: Node = get_tree().get_first_node_in_group("panic_counter")
		if panic != null:
			lines.append("panic: %.1f" % float(panic.get("value")))
	var body: Node = get_tree().get_first_node_in_group("body")
	if body is CharacterBody2D:
		var b: CharacterBody2D = body
		lines.append("body: (%.0f, %.0f)  v(%.0f, %.0f)  %s" % [
				b.global_position.x, b.global_position.y, b.velocity.x, b.velocity.y,
				"floor" if b.is_on_floor() else "air"])
	lines.append("F1 body · F2 mind · F3 all · F4 fail · F5 restart · F6/F7 prev/next · F8 reunion · F9 hide · F10 slow")
	return "\n".join(lines)


func _build_overlay() -> void:
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	_overlay.visible = false
	_label = Label.new()
	_label.position = Vector2(8, 40)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color("f1ffaf"))
	_label.add_theme_color_override("font_outline_color", Color("201c02"))
	_label.add_theme_constant_override("outline_size", 4)
	_overlay.add_child(_label)
	add_child(_overlay)
