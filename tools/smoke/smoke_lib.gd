extends RefCounted
## Shared helpers for the smoke scripts in tools/smoke/.
##
## Each smoke script is a SceneTree script run headless:
##     godot --headless --path . -s tools/smoke/<name>.gd
## `tools/smoke_test.sh` runs them all and turns the output into one exit code.
##
## Why SceneTree scripts: `-s` replaces the main scene with a script that *is*
## the main loop, so we can load scenes, poke nodes and await real timers with
## nothing on screen. Autoloads (Game, Events) still exist under root at
## runtime, but the parser doesn't know their names in this mode — that is what
## autoload() below is for.
## Docs: https://docs.godotengine.org/en/stable/classes/class_scenetree.html

static var failures: int = 0
static var checks: int = 0


static func ok(msg: String) -> void:
	checks += 1
	print("  ok    ", msg)


static func fail(msg: String) -> void:
	checks += 1
	failures += 1
	print("  FAIL  ", msg)


## Something worth a human's eye that does not make the suite red.
static func warn(msg: String) -> void:
	print("  warn  ", msg)


static func check(cond: bool, msg: String) -> void:
	if cond:
		ok(msg)
	else:
		fail(msg)


## Print the verdict line the shell runner greps for, and exit with 0/1.
static func finish(tree: SceneTree, suite: String) -> void:
	if failures == 0:
		print("SMOKE PASS  %s  (%d checks)" % [suite, checks])
	else:
		print("SMOKE FAIL  %s  (%d of %d checks failed)" % [suite, failures, checks])
	tree.quit(1 if failures > 0 else 0)


## Fetch an autoload by name. See the header comment.
static func autoload(tree: SceneTree, name: String) -> Node:
	return tree.root.get_node_or_null(name)


## Poll `pred` every frame until it returns true or `timeout` real seconds pass.
## Real time (not frame counts) because headless runs are uncapped — a "wait
## 60 frames" can be 0.1 s on one machine and 1 s on another.
static func wait_until(tree: SceneTree, pred: Callable, timeout: float) -> bool:
	var deadline: int = Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if pred.call():
			return true
		await tree.process_frame
	return bool(pred.call())


## Instance id of the current scene, or 0. Lambdas that poll for a scene
## change must capture THIS, not the Node: once the scene is freed a captured
## Node becomes a "Lambda capture was freed" engine error on every poll.
static func scene_id(tree: SceneTree) -> int:
	return tree.current_scene.get_instance_id() if tree.current_scene != null else 0


## Wait until the current scene is a different instance from `old_id` (and, if
## `path` is given, has that scene_file_path). Returns the new scene or null.
static func wait_for_scene(tree: SceneTree, old_id: int, timeout: float, path: String = "") -> Node:
	var arrived: bool = await wait_until(tree, func() -> bool:
		var sid: int = scene_id(tree)
		if sid == 0 or sid == old_id:
			return false
		return path.is_empty() or tree.current_scene.scene_file_path == path, timeout)
	return tree.current_scene if arrived else null


## Sleep `seconds` of game time.
static func sleep(tree: SceneTree, seconds: float) -> void:
	await tree.create_timer(seconds).timeout


## Recursively collect files under `dir_path` whose extension is in `exts`.
static func list_files(dir_path: String, exts: PackedStringArray, out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if dir.current_is_dir():
			if not name.begins_with("."):
				list_files(dir_path.path_join(name), exts, out)
		elif exts.has(name.get_extension()):
			out.append(dir_path.path_join(name))
		name = dir.get_next()
	dir.list_dir_end()


## Every WinCondition under `scene` (any depth, across instanced sub-scenes),
## duck-typed so this file has no dependency on the class_name being loaded.
static func win_conditions(scene: Node) -> Array[Node]:
	var out: Array[Node] = []
	for n in scene.find_children("*", "Node", true, false):
		if n.has_method("satisfy") and "key" in n and "is_satisfied" in n:
			out.append(n)
	return out


## The Sun in a scene (the node running scenes/sun/sun.gd), or null.
static func sun_of(scene: Node) -> Node:
	for n in scene.find_children("*", "Node2D", true, false):
		if "day_length" in n and n.has_signal("sunset"):
			return n
	return null


## First node of `type` under `scene`, or null.
static func first_of(scene: Node, type: String) -> Node:
	var found: Array[Node] = scene.find_children("*", type, true, false)
	return found[0] if not found.is_empty() else null


## Scenes listed here are reported but do not fail the suite. One line each:
##     res://path/to/scene.tscn | why it is allowed to be broken, and whose call it is
static func known_broken() -> Dictionary:
	var out: Dictionary = {}
	var f: FileAccess = FileAccess.open("res://tools/smoke/known_broken.txt", FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var line: String = f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts: PackedStringArray = line.split("|", false, 1)
		out[parts[0].strip_edges()] = parts[1].strip_edges() if parts.size() > 1 else ""
	return out
