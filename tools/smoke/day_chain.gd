extends SceneTree
## Smoke: the day chain reaches the reunion.
##
## Drives Game.start_days(), force-satisfies every WinCondition in each day as
## it loads, and asserts that the head leaves and the next day in
## Game.DAY_SCENES appears — in order — ending at Game.REUNION_SCENE. This is
## the "does the plumbing still connect" test: no physics skill, just the
## signal chain WinCondition → manager → head.release() → left_scene → next
## scene, for both flow systems. (The one input it gives is "hold right" in a
## transition, whose body is the player's.)

const Smoke := preload("res://tools/smoke/smoke_lib.gd")

## Generous: the slowest exit is the head travelling from x≈450 to x=704 at 180 px/s.
const EXIT_TIMEOUT: float = 6.0


func _initialize() -> void:
	_run()


func _run() -> void:
	# Nothing is in the tree during _initialize (root enters the tree right
	# after it returns), so autoloads can't get_tree() yet. One frame fixes it.
	await process_frame
	var game: Node = Smoke.autoload(self, "Game")
	if game == null:
		Smoke.fail("Game autoload missing")
		Smoke.finish(self, "day_chain")
		return
	var days: Array = game.get("DAY_SCENES")
	var reunion: String = str(game.get("REUNION_SCENE"))

	var sid: int = Smoke.scene_id(self)
	game.call("start_days")
	for i in days.size():
		var path: String = str(days[i])
		var scene: Node = await Smoke.wait_for_scene(self, sid, 3.0, path)
		Smoke.check(scene != null, "day %d loaded: %s" % [i, path.get_file()])
		if scene == null:
			break
		sid = scene.get_instance_id()
		if path.begins_with("res://scenes/transition/"):
			# The body is the player's in a transition and the beat ends when it
			# reaches the head — so hold "right" (the real action, like a key)
			# until the scene hands off.
			Input.action_press("move_right", 1.0)
			var after: Node = await Smoke.wait_for_scene(self, sid, 10.0)
			Input.action_release("move_right")
			Smoke.check(after != null, "  transition played through (body run to the head) and moved on")
			if after == null:
				break
			continue
		await Smoke.sleep(self, 0.3)

		var conds: Array[Node] = Smoke.win_conditions(scene)
		Smoke.check(conds.size() > 0, "  %d WinCondition(s) found" % conds.size())
		var head: Node = get_first_node_in_group("head")
		var released: Array[bool] = [false]
		if head != null:
			head.connect("released", func() -> void: released[0] = true)
		for c in conds:
			c.call("satisfy")
		await Smoke.sleep(self, 0.1)
		Smoke.check(head == null or released[0], "  head.release() was called after the last need")

		var next: Node = await Smoke.wait_for_scene(self, sid, EXIT_TIMEOUT)
		Smoke.check(next != null, "  scene advanced after the head left")
		if next == null:
			break

	var at_reunion: bool = current_scene != null and current_scene.scene_file_path == reunion
	Smoke.check(at_reunion, "ended at the reunion: %s" % reunion.get_file())
	Smoke.finish(self, "day_chain")
