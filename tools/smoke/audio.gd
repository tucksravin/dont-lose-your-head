extends SceneTree
## Smoke: the audio scaffold is sound. Every cue in Sfx.CUES is a legal file
## stem, every declared cue either has a file or is reported missing (warn, not
## fail — silence is the designed state until Tucker/Ben record), an unknown
## cue is a warning not a crash, and the cues actually FIRE at the right
## moments: a scripted jump produces jump + land, satisfying a need produces
## need_met, winning produces day_won + head_roll, sunset produces day_failed.

const Smoke := preload("res://tools/smoke/smoke_lib.gd")

var _fired: Array[StringName] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var sfx: Node = Smoke.autoload(self, "Sfx")
	var music: Node = Smoke.autoload(self, "Music")
	var game: Node = Smoke.autoload(self, "Game")
	Smoke.check(sfx != null and music != null, "Sfx and Music autoloads present")
	if sfx == null:
		Smoke.finish(self, "audio")
		return
	sfx.connect("played", func(cue: StringName) -> void: _fired.append(cue))

	var cues: Dictionary = sfx.get("CUES")
	for cue in cues:
		var stem: String = String(cue)
		Smoke.check(stem.is_valid_filename() and stem == stem.to_lower() and not stem.contains(" "),
				"cue '%s' is a legal file stem" % stem)
	var missing: Array = sfx.call("missing")
	if missing.is_empty():
		Smoke.ok("every cue has a file")
	else:
		Smoke.warn("%d/%d cues have no file yet (expected until recorded): %s" % [missing.size(), cues.size(), ", ".join(missing)])
	Smoke.check(AudioServer.get_bus_index("SFX") >= 0 and AudioServer.get_bus_index("Music") >= 0,
			"SFX and Music buses exist (default_bus_layout.tres)")

	# Unknown cue: a warning, not an error or crash.
	sfx.call("play", &"definitely_not_a_cue")
	Smoke.ok("unknown cue did not crash")

	# Now fire real moments.
	game.call("go_to", 0)
	var scene: Node = await Smoke.wait_for_scene(self, 0, 3.0, str(game.get("DAY_SCENES")[0]))
	Smoke.check(scene != null, "day 0 loaded")
	if scene == null:
		Smoke.finish(self, "audio")
		return
	await Smoke.sleep(self, 0.3)
	Smoke.check(str(music.get("current_track")) == "day", "music picked the generic 'day' track for a day (got '%s')" % music.get("current_track"))

	_fired.clear()
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	await Smoke.sleep(self, 1.0)  # hang time is 0.61 s
	Smoke.check(_fired.has(&"jump"), "jump fired 'jump'")
	Smoke.check(_fired.has(&"land"), "landing fired 'land'")

	_fired.clear()
	var conds: Array[Node] = Smoke.win_conditions(scene)
	conds[0].call("satisfy")
	await Smoke.sleep(self, 0.1)
	Smoke.check(_fired.count(&"need_met") == 1, "one need → one 'need_met' (%d)" % _fired.count(&"need_met"))
	Smoke.check(not _fired.has(&"day_won"), "…and not 'day_won' yet")
	for c in conds:
		c.call("satisfy")
	await Smoke.sleep(self, 0.1)
	Smoke.check(_fired.has(&"day_won"), "all needs → 'day_won'")
	Smoke.check(_fired.has(&"head_roll"), "release → 'head_roll'")

	# Sunset on a fresh day → day_failed.
	var next: Node = await Smoke.wait_for_scene(self, scene.get_instance_id(), 6.0)
	game.call("go_to", 0)
	scene = await Smoke.wait_for_scene(self, next.get_instance_id() if next != null else 0, 3.0)
	await Smoke.sleep(self, 0.2)
	_fired.clear()
	var sun: Node = Smoke.sun_of(scene)
	sun.set("day_length", 0.01)
	await Smoke.sleep(self, 0.3)
	Smoke.check(_fired.has(&"day_failed"), "sunset → 'day_failed'")

	Smoke.finish(self, "audio")
