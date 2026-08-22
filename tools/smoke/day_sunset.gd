extends SceneTree
## Smoke: every day reacts to sunset, and a won day ignores it.
##
## DESIGN §2.1 "Timer & fail" / TASKS T3: the sun running out fails the day
## (instant restart is the undecided-default; Sean's days show a game-over card
## instead — both count as "reacted" here). For each day in Game.DAY_SCENES:
##   1. load it, shrink the sun's day_length so sunset fires at once, and expect
##      the scene to reload OR a game-over overlay to appear (tree paused).
##   2. load it again, win it, then force sunset mid-exit, and expect the NEXT
##      scene — not this day reloaded. ("a won day ignores it", T3.)

const Smoke := preload("res://tools/smoke/smoke_lib.gd")


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame  # see day_chain.gd — autoloads aren't in the tree during _initialize
	var game: Node = Smoke.autoload(self, "Game")
	var days: Array = game.get("DAY_SCENES")

	for i in days.size():
		var path: String = str(days[i])
		print("-- ", path.get_file())

		# 1. sunset on a live day → fail path
		var scene: Node = await _load_day(game, i, path)
		if scene == null:
			continue
		var sid: int = scene.get_instance_id()
		var sun: Node = Smoke.sun_of(scene)
		Smoke.check(sun != null, "has a Sun")
		if sun == null:
			continue
		sun.set("day_length", 0.01)
		var reacted: bool = await Smoke.wait_until(self, func() -> bool:
			return paused or Smoke.scene_id(self) != sid, 3.0)
		var how: String = "game-over card (tree paused)" if paused else ("scene reloaded" if reacted else "nothing happened")
		Smoke.check(reacted, "sunset fails the day → %s" % how)
		if paused:
			paused = false

		# 2. sunset on a won day → ignored
		scene = await _load_day(game, i, path)
		if scene == null:
			continue
		sid = scene.get_instance_id()
		sun = Smoke.sun_of(scene)
		for c in Smoke.win_conditions(scene):
			c.call("satisfy")
		await Smoke.sleep(self, 0.15)  # the head is now on its way out
		sun.set("day_length", 0.01)
		var next: Node = await Smoke.wait_for_scene(self, sid, 6.0)
		var restarted: bool = next != null and next.scene_file_path == path
		Smoke.check(next != null and not restarted and not paused,
				"sunset during the exit does not restart a won day (%s)" %
				("restarted!" if restarted else ("paused!" if paused else ("advanced" if next != null else "stuck"))))
		if paused:
			paused = false

	Smoke.finish(self, "day_sunset")


func _load_day(game: Node, index: int, path: String) -> Node:
	var before: int = Smoke.scene_id(self)
	game.call("go_to", index)
	var scene: Node = await Smoke.wait_for_scene(self, before, 3.0, path)
	if scene == null:
		Smoke.fail("could not load %s" % path)
		return null
	await Smoke.sleep(self, 0.2)
	return scene
