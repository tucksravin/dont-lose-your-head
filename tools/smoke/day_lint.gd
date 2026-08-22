extends SceneTree
## Smoke: every day scene has the parts a day needs, and Game's day list is sane.
##
## A day is "one new file that runs end to end with no edits elsewhere"
## (TASKS.md T8). This is the checklist, executed: each day on disk is
## instantiated and inspected — one head, one body, one sun, a camera, a
## win-condition manager, at least one WinCondition. Both need keys is a `warn`,
## not a fail, because DESIGN §2.1 wants body + mind per day but the team has
## shipped a mind-only day on purpose (day_panic) — that's their call to keep.
##
## Also checks Game.DAY_SCENES: every entry exists, and the ordering constraint
## documented in game.gd (a DayManager day must be last) holds.

const Smoke := preload("res://tools/smoke/smoke_lib.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	var known: Dictionary = Smoke.known_broken()
	var game: Node = Smoke.autoload(self, "Game")
	Smoke.check(game != null, "Game autoload present")
	var day_list: Array = game.get("DAY_SCENES") if game != null else []

	var days: Array[String] = []
	Smoke.list_files("res://scenes/days", ["tscn"], days)
	days.sort()

	for path in days:
		print("-- ", path)
		if known.has(path):
			Smoke.warn("skipped  [known: %s]" % known[path])
			continue
		await _lint_day(path)
		if not day_list.has(path):
			Smoke.warn("%s is on disk but not in Game.DAY_SCENES (orphan, or work in progress)" % path.get_file())

	print("-- Game.DAY_SCENES")
	var last_manager_index: int = -1
	var first_events_after_manager: bool = false
	for i in day_list.size():
		var p: String = str(day_list[i])
		Smoke.check(FileAccess.file_exists(p), "DAY_SCENES[%d] exists: %s" % [i, p])
		if _uses_day_manager(p):
			last_manager_index = i
		elif last_manager_index >= 0:
			first_events_after_manager = true
	Smoke.check(not first_events_after_manager,
			"no Events-system day sits after a DayManager day (DayManager jumps straight to its own next_scene — see game.gd)")
	Smoke.check(day_list.size() > 0, "DAY_SCENES is not empty")

	Smoke.finish(self, "day_lint")


func _lint_day(path: String) -> void:
	var ps: PackedScene = load(path)
	if ps == null:
		Smoke.fail("%s failed to load" % path)
		return
	var day: Node = ps.instantiate()
	root.add_child(day)
	await process_frame
	await process_frame

	var heads: Array[Node] = get_nodes_in_group("head")
	var bodies: Array[Node] = get_nodes_in_group("body")
	Smoke.check(heads.size() == 1, "exactly one head (group 'head'): %d" % heads.size())
	Smoke.check(heads.size() == 1 and heads[0].has_method("release") and heads[0].has_signal("left_scene"),
			"head has release() and left_scene")
	Smoke.check(bodies.size() == 1 and bodies[0] is CharacterBody2D, "exactly one body (group 'body', CharacterBody2D): %d" % bodies.size())
	Smoke.check(Smoke.sun_of(day) != null, "has a Sun (day timer)")
	Smoke.check(Smoke.first_of(day, "Camera2D") != null, "has a Camera2D")

	var wc_old: Node = _first_with_script(day, "res://scenes/gameplay/win_conditions.gd")
	var wc_mgr: Node = Smoke.first_of(day, "WinConditionManager")
	Smoke.check(wc_old != null or wc_mgr != null, "has a win-condition manager (%s)" %
			("WinConditions/Events" if wc_old != null else ("WinConditionManager/DayManager" if wc_mgr != null else "none")))
	if wc_mgr != null:
		Smoke.check(Smoke.first_of(day, "DayManager") != null, "WinConditionManager is paired with a DayManager")

	var conds: Array[Node] = Smoke.win_conditions(day)
	Smoke.check(conds.size() >= 1, "has at least one WinCondition: %d" % conds.size())
	var keys: Array[String] = []
	for c in conds:
		keys.append(str(c.get("key")))
	if not (keys.has("body") and keys.has("mind")):
		Smoke.warn("needs present: %s — DESIGN §2.1 wants one body + one mind per day" % str(keys))

	if heads.size() == 1 and bodies.size() == 1:
		var gap: float = (heads[0] as Node2D).global_position.distance_to((bodies[0] as Node2D).global_position)
		Smoke.check(gap > 48.0, "head and body start apart (%.0f px)" % gap)

	var background: Node = day.get_node_or_null("Background")
	if background == null:
		Smoke.warn("no 'Background' node — sky will be the clear colour, not the palette")

	day.queue_free()
	await process_frame
	# The head/body groups are per-node; freeing the scene empties them.
	await process_frame


func _first_with_script(scene: Node, script_path: String) -> Node:
	for n in scene.find_children("*", "Node", true, false):
		var s: Script = n.get_script() as Script
		if s != null and s.resource_path == script_path:
			return n
	return null


## True if the scene runs on Sean's DayManager system: it references
## day_manager.gd directly, or any script it references `extends DayManager`.
func _uses_day_manager(path: String) -> bool:
	var text: String = FileAccess.get_file_as_string(path)
	if text.contains("day_manager.gd"):
		return true
	var re: RegEx = RegEx.new()
	re.compile("\\[ext_resource type=\"Script\"[^\\]]*path=\"(res://[^\"]+\\.gd)\"")
	for m in re.search_all(text):
		var src: String = FileAccess.get_file_as_string(m.get_string(1))
		if src.contains("extends DayManager"):
			return true
	return false
