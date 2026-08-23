extends SceneTree
## Smoke: the whole game can be PLAYED from the intro to the end card, by a bot.
## (From the *intro* — the landing screen before it is a mouse/UI click, see
## START_SCENE.)
##
## This is the test that asks "is it completable", not "does it load". A tiny
## bot presses the real input actions (Input.action_press / action_release —
## the same path a keyboard takes, so body.gd is exercised unmodified) and
## follows a per-scene plan: walk to x, jump, wait, tap an action, wait for a
## need to be satisfied. Every scene must hand off to the next within its
## budget, and no scene may reappear (that would mean a restart/fail fired).
##
## When a day's layout changes, update its plan below — a plan that can no
## longer be executed is exactly the signal we want.
##
## Plans are dictionaries keyed by scene path. Steps:
##   {"walk_to": x}             hold left/right until |body.x − x| < 4 (8 s cap)
##   {"jump": true}             tap jump for one physics tick
##   {"wait": s}                sleep s seconds of game time
##   {"press": "restart"}       tap an action (no scene needs one today)
##   {"satisfied": "body"}      wait until the WinCondition with that key is met
##   {"release_all": true}      let go of every held action
##   {"run": "move_right"}      hold an action until the scene changes (10 s cap)
## A scene with no plan just waits for the scene to change. A
## TRANSITION with no plan gets {"run": "move_right"}: the body is the player's
## there and the beat ends when it reaches the head, so running right is the
## plan for every fork. A DAY with no plan is force-satisfied with a warning, so
## a work-in-progress day doesn't turn the suite red — but it isn't proven either.

const Smoke := preload("res://tools/smoke/smoke_lib.gd")

## The run really starts at scenes/ui/title.tscn, but that screen is a Button
## click and the bot presses *actions* (Input.action_press), which never reaches
## Control input — so the suite starts one scene later, at the intro. The title
## is covered by load_all instead.
const START_SCENE: String = "res://scenes/intro/intro.tscn"
## Per-scene budget, real seconds. Below the 30 s sun on purpose.
const SCENE_BUDGET: float = 25.0

var plans: Dictionary = {
	# The intro is a cutscene now (Sat): it takes no input at all and hands off
	# on its own after ~10.8 s — the head pops off and rolls away. An empty plan
	# means "just wait for the scene to change", which is exactly right, and the
	# 25 s scene budget covers it. It must NOT be {"run": …}: that step gives up
	# after 10 s, which is shorter than the cutscene.
	"res://scenes/intro/intro.tscn": [],
	"res://scenes/days/day_velma.tscn": [
		# Body starts at 80. Walk right to the first step, then climb
		# left/up: 560/500/440/380 then glasses at 320. Pickup locks the
		# body and auto-throws.
		{"walk_to": 535.0}, {"jump": true}, {"wait": 0.7},
		{"walk_to": 475.0}, {"jump": true}, {"wait": 0.7},
		{"walk_to": 415.0}, {"jump": true}, {"wait": 0.7},
		{"walk_to": 355.0}, {"jump": true}, {"wait": 0.7},
		{"walk_to": 320.0}, {"satisfied": "body"},
		{"wait": 2.2}, {"satisfied": "mind"},
	],
	"res://scenes/days/day_template.tscn": [
		{"walk_to": 200.0}, {"satisfied": "mind"},
		{"walk_to": 500.0}, {"satisfied": "body"},
	],
	"res://scenes/days/day_panic_still.tscn": [
		# Stand still from spawn. PanicCounter win_on_zero satisfies both needs.
		{"satisfied": "mind"},
	],
	"res://scenes/days/day_panic.tscn": [
		# Run to the floor button under the hanging cage (520,320) — reaching
		# it frees the cage, no key. Panic no longer wins on zero. Kikis may
		# still hit the bot.
		{"walk_to": 520.0}, {"wait": 0.3}, {"satisfied": "mind"},
	],
	"res://scenes/days/platforming_day.tscn": [
		# Three one-way steps, 36 px apart (max jump 45.9 px): stand under
		# each, jump straight up, land on it. Then the high goal drops the
		# bridge, then walk across to the far goal.
		{"walk_to": 60.0}, {"jump": true}, {"wait": 0.7},
		{"walk_to": 118.0}, {"jump": true}, {"wait": 0.7},
		{"walk_to": 178.0}, {"jump": true}, {"wait": 0.7},
		{"walk_to": 203.0}, {"satisfied": "body"},
		{"wait": 0.8},
		# The head (450,306) is a solid 28×28 box on the path to the far goal —
		# a running jump from x≈405 clears it (see journal: intended?).
		{"walk_to": 405.0}, {"jump": true},
		{"walk_to": 560.0}, {"satisfied": "mind"},
	],
	# Nothing to press any more: walking within 64 px of the head dives.
	"res://scenes/reunion/reunion.tscn": [
		{"walk_to": 430.0}, {"wait": 0.5},
	],
}

var _held: Array[String] = []


func _initialize() -> void:
	_run()


func _run() -> void:
	change_scene_to_file(START_SCENE)
	var ok: bool = await Smoke.wait_until(self, func() -> bool: return Smoke.scene_id(self) != 0, 3.0)
	Smoke.check(ok, "intro loaded")
	var seen: Array[String] = []
	var reunion_next: String = ""
	while ok:
		var scene: Node = current_scene
		var sid: int = scene.get_instance_id()
		var path: String = scene.scene_file_path
		if seen.has(path):
			Smoke.fail("%s appeared again — a restart or fail fired" % path.get_file())
			break
		seen.append(path)
		if path == "res://scenes/reunion/reunion.tscn":
			reunion_next = str(scene.get("next_scene"))
		if reunion_next != "" and path == reunion_next:
			Smoke.ok("reached the scene after the reunion: %s" % path.get_file())
			break
		print("-- ", path.get_file())
		var started: int = Time.get_ticks_msec()
		await Smoke.sleep(self, 0.25)
		var plan: Array = plans.get(path, [])
		if plan.is_empty() and path.begins_with("res://scenes/transition/"):
			plan = [{"run": "move_right"}]
		if plan.is_empty() and path.begins_with("res://scenes/days/"):
			# A WIP day: keep the suite green but say so loudly — a plan is what
			# proves the day is completable by a player, not just by a cheat.
			Smoke.warn("no bot plan for %s — force-satisfying its needs; add a plan in play_through.gd" % path.get_file())
			for c in Smoke.win_conditions(scene):
				c.call("satisfy")
		var plan_ok: bool = await _execute(sid, plan)
		_release_all()
		if not plan_ok:
			Smoke.fail("plan for %s could not be completed" % path.get_file())
			break
		var remaining: float = SCENE_BUDGET - (Time.get_ticks_msec() - started) / 1000.0
		var moved: bool = (await Smoke.wait_for_scene(self, sid, maxf(remaining, 1.0))) != null
		Smoke.check(moved, "%s handed off to the next scene in %.1f s" % [path.get_file(), (Time.get_ticks_msec() - started) / 1000.0])
		ok = moved
	Smoke.finish(self, "play_through")


func _execute(sid: int, plan: Array) -> bool:
	for step in plan:
		if Smoke.scene_id(self) != sid:
			return true  # the scene moved on early — fine, the rest is moot
		var s: Dictionary = step
		if s.has("walk_to"):
			if not await _walk_to(sid, float(s["walk_to"])):
				return false
		elif s.has("jump"):
			await _tap("jump")
		elif s.has("wait"):
			await Smoke.sleep(self, float(s["wait"]))
		elif s.has("press"):
			await _tap(str(s["press"]))
		elif s.has("satisfied"):
			var key: String = str(s["satisfied"])
			var met: bool = await Smoke.wait_until(self, func() -> bool:
				if Smoke.scene_id(self) != sid:
					return true
				for c in Smoke.win_conditions(current_scene):
					if str(c.get("key")) == key and bool(c.get("is_satisfied")):
						return true
				return false, 12.0)
			Smoke.check(met, "  need '%s' satisfied" % key)
			if not met:
				return false
		elif s.has("release_all"):
			_release_all()
		elif s.has("run"):
			var action: String = str(s["run"])
			_hold(action)
			var gone: bool = (await Smoke.wait_for_scene(self, sid, 10.0)) != null
			_release(action)
			Smoke.check(gone, "  holding '%s' got the scene to hand off" % action)
			if not gone:
				return false
	return true


## The body in the current scene, or null (also null once the scene is gone).
func _body(sid: int) -> CharacterBody2D:
	if Smoke.scene_id(self) != sid:
		return null
	for n in get_nodes_in_group("body"):
		if n is CharacterBody2D and current_scene.is_ancestor_of(n):
			return n
	return null


func _body_x(sid: int) -> float:
	var b: CharacterBody2D = _body(sid)
	return b.global_position.x if b != null else NAN


func _walk_to(sid: int, x: float) -> bool:
	var start_x: float = _body_x(sid)
	if is_nan(start_x):
		Smoke.fail("  no body to walk")
		return false
	var dir: String = "move_right" if x > start_x else "move_left"
	_hold(dir)
	var arrived: bool = await Smoke.wait_until(self, func() -> bool:
		var bx: float = _body_x(sid)
		return is_nan(bx) or absf(bx - x) < 4.0, 8.0)
	_release(dir)
	await physics_frame
	if not arrived:
		Smoke.fail("  walk_to %.0f stalled at x=%.0f" % [x, _body_x(sid)])
	return arrived


func _hold(action: String) -> void:
	if not _held.has(action):
		_held.append(action)
	Input.action_press(action, 1.0)


func _release(action: String) -> void:
	_held.erase(action)
	Input.action_release(action)


func _release_all() -> void:
	for a in _held.duplicate():
		_release(a)


## Press for one physics tick so is_action_just_pressed() sees it exactly once.
func _tap(action: String) -> void:
	Input.action_press(action, 1.0)
	await physics_frame
	await physics_frame
	Input.action_release(action)
