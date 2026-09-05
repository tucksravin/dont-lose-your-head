extends Node
## Touch controls (autoload: `Touch`) — a drag stick that appears **wherever the
## finger lands**, so nothing sits permanently on top of any scene (Tucker, Sat:
## "is drag joystick wherever you touch feasible? … theres definitely at least
## some dead space in every scene"). One gesture covers all four directions.
##
## **No day, transition or body script changes for this.** Everything the game
## reads goes through input *actions* (README/CLAUDE §5, "input through actions,
## never key codes") and there are only four of them:
##   `move_left` / `move_right`  held, read by `Input.get_axis()` in body.gd
##   `jump` / `move_down`        edges, read by `Input.is_action_just_pressed()`
## So this just presses those, and every scene believes it is a keyboard.
##
## **day_mirror gets its inversion for free.** That day flips jump to `move_down`
## (`Body.invert_vertical`) and left/right via `Body.move_sign`. Push up to jump
## normally, push *down* to jump while the head is staring at the glass — same
## gesture, and the horizontal flip needs nothing here at all because body.gd
## applies `move_sign` itself.
##
## Why a plain Node and not a full-screen Control: `_unhandled_input` runs
## *after* Control `_gui_input`, so the title screen's Play button and the game
## over Retry button keep eating their own taps with nothing wired up. A
## full-screen Control would have swallowed them.
##
## Why `Input.action_press()` and not a fake `InputEventAction`: both work
## (measured 6/6 edges each), and this one is fewer moving parts. The catch is
## *where* you call it — from inside a frame callback like `_process` the edge
## lands correctly, but from a coroutine that resumes *between* frames it is
## silently lost. That is why `_release_edges()` waits for the physics frame
## counter to actually advance before letting go of `jump`: process frames can
## outrun physics frames, and a press+release inside one physics tick would
## never be seen by `body.gd`.
##
## Docs: https://docs.godotengine.org/en/stable/tutorials/inputs/inputevent.html
## https://docs.godotengine.org/en/stable/classes/class_inputeventscreentouch.html

## Tunables — plain vars, not @export: an autoload has no Inspector, edit here.
## (Same reasoning as Sfx/Music.)
##
## Show the stick even without a touchscreen, and let the **mouse** drive it —
## press, drag, release stands in for a finger. Flip this to true to try the
## controls on a desktop; there is no other way, because a mouse does not
## produce touch events and `input_devices/pointing/emulate_touch_from_mouse`
## is off (turning THAT on would make every click in the game a touch, which is
## a project-wide behaviour change nobody asked for).
var force_on: bool = false
## Push (px, in the 640×360 viewport) before left/right registers at all.
var deadzone: float = 8.0
## Push before up/down fires a jump. Deliberately further than `deadzone` so a
## sloppy horizontal drag doesn't jump.
var jump_threshold: float = 24.0
## Push at which the stick reads as fully over. Also the drawn ring's radius.
var max_radius: float = 40.0
## Once up/down has fired, the finger must come back inside this to re-arm, so
## holding the stick up doesn't machine-gun jumps. Held-down auto-repeat is not
## something the keyboard does either (`is_action_just_pressed`).
var rearm_inside: float = 14.0
## Walk speed matches the keyboard's on/off rather than how far the stick is
## pushed. `Input.get_axis()` passes analog strength straight through (measured:
## press at 0.35 reads back 0.35) and body.gd does `direction * speed`, so
## flipping this to false gives real variable-speed walking — but it would also
## change how every day plays, which is why it ships off. **Tucker: one flag.**
var binary_walk: bool = true

## Emitted when the stick starts and stops, in case anything ever wants to hide
## HUD text under a thumb. Nothing listens yet.
signal stick_started(at: Vector2)
signal stick_ended

## `_touch_index` when the stick is being driven by the mouse rather than a
## finger. Real touch indices start at 0, and -1 already means "nothing", so a
## separate sentinel keeps the two from being confused.
const MOUSE_INDEX: int = -2

var _enabled: bool = false
var _touch_index: int = -1
var _origin: Vector2 = Vector2.ZERO
var _offset: Vector2 = Vector2.ZERO
## Which of `jump` / `move_down` we are currently holding, and since which
## physics frame — see the header for why the frame number matters.
var _edge_action: StringName = &""
var _edge_frame: int = -1
## True while the finger is still past `jump_threshold` and has not come back
## inside `rearm_inside`; blocks a second jump from one push.
var _edge_armed: bool = true
var _layer: CanvasLayer
var _draw: Control


func _ready() -> void:
	set_enabled(force_on or DisplayServer.is_touchscreen_available())


## Turn the stick on or off at runtime. `_ready()` calls it with whatever
## `DisplayServer.is_touchscreen_available()` says; call it yourself to force
## the stick on a desktop (there is no touchscreen to ask), or to give a future
## options menu something to flip. Off costs nothing: no overlay is built and
## both callbacks are switched off.
func set_enabled(on: bool) -> void:
	_enabled = on
	set_process(on)
	set_process_unhandled_input(on)
	if not on:
		_stop_quiet()
		if _layer != null:
			_layer.queue_free()
			_layer = null
			_draw = null
		return
	if _layer == null:
		_build_overlay()


## True while the stick is switched on for this device.
func is_enabled() -> bool:
	return _enabled


## Drop the stick without emitting — used when switching off entirely.
func _stop_quiet() -> void:
	_touch_index = -1
	_offset = Vector2.ZERO
	_release_all()


## The stick's own CanvasLayer, above everything the game draws (the scenes'
## fade overlays sit at layer 10).
func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 50
	add_child(_layer)
	_draw = Control.new()
	# IGNORE so the overlay never eats a tap meant for a real button underneath.
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_draw.draw.connect(_on_draw)
	_layer.add_child(_draw)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_start(touch.index, touch.position)
		elif touch.index == _touch_index:
			_stop()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _touch_index:
			_offset = drag.position - _origin
			_draw.queue_redraw()
	elif event is InputEventMouseButton:
		# Desktop stand-in for a finger; only ever reached when `force_on` put
		# the stick up on a machine with no touchscreen. A real phone sends
		# InputEventScreenTouch and never comes through here.
		if not force_on:
			return
		var click: InputEventMouseButton = event
		if click.button_index != MOUSE_BUTTON_LEFT:
			return
		if click.pressed:
			_start(MOUSE_INDEX, click.position)
		elif _touch_index == MOUSE_INDEX:
			_stop()
	elif event is InputEventMouseMotion and _touch_index == MOUSE_INDEX:
		_offset = (event as InputEventMouseMotion).position - _origin
		_draw.queue_redraw()


## The body the player is actually driving right now, or null.
##
## `is_scripted` is exactly the right question, not "does a body exist": the
## title screen and the thanks card both instance a REAL body and walk it in
## place, and body.gd's `_physics_process` returns early for those, so a stick
## there would press actions nothing reads and draw a ring over a menu. Gating
## on it also lands two behaviours for free — the stick appears the instant the
## intro hands control over (`intro.gd::_hand_over()` clears the flag) and
## disappears the instant a transition takes it away again
## (`transition.gd` sets it when the body reaches the stopped head).
##
## The body adds itself to the "body" group in its own `_ready()` (body.gd).
func _player_body() -> CharacterBody2D:
	var body: CharacterBody2D = get_tree().get_first_node_in_group("body") as CharacterBody2D
	if body == null or not is_instance_valid(body) or bool(body.get("is_scripted")):
		return null
	return body


func _start(index: int, at: Vector2) -> void:
	if _touch_index != -1:
		return  # already driving with another finger; ignore extra ones
	if _player_body() == null:
		return
	_touch_index = index
	_origin = at
	_offset = Vector2.ZERO
	_edge_armed = true
	_draw.queue_redraw()
	stick_started.emit(at)


func _stop() -> void:
	_touch_index = -1
	_offset = Vector2.ZERO
	_release_all()
	_draw.queue_redraw()
	stick_ended.emit()


func _process(_delta: float) -> void:
	_release_edges()
	if _touch_index == -1:
		return
	# Control can be taken away mid-gesture — a transition does exactly that
	# when the body reaches the stopped head. Drop the stick rather than leaving
	# a ring on screen and actions held down.
	if _player_body() == null:
		_stop()
		return
	_apply_horizontal()
	_apply_vertical()


func _apply_horizontal() -> void:
	var dx: float = _offset.x
	if absf(dx) <= deadzone:
		_press(&"move_left", 0.0)
		_press(&"move_right", 0.0)
		return
	var strength: float = 1.0
	if not binary_walk:
		# Ramp from the edge of the deadzone, not from centre, so the first
		# pixel past the deadzone doesn't jump straight to a third of speed.
		strength = clampf((absf(dx) - deadzone) / maxf(1.0, max_radius - deadzone), 0.0, 1.0)
	if dx < 0.0:
		_press(&"move_right", 0.0)
		_press(&"move_left", strength)
	else:
		_press(&"move_left", 0.0)
		_press(&"move_right", strength)


## Up fires `jump`, down fires `move_down`. body.gd decides which one counts —
## normally `jump`, and `move_down` while a day has set `invert_vertical`. Both
## are one-shot edges, so this fires once per push and re-arms on the way back.
func _apply_vertical() -> void:
	var dy: float = _offset.y
	if absf(dy) < rearm_inside:
		_edge_armed = true
		return
	if not _edge_armed or _edge_action != &"":
		return
	if dy <= -jump_threshold:
		_fire(&"jump")
	elif dy >= jump_threshold:
		_fire(&"move_down")


func _fire(action: StringName) -> void:
	_edge_armed = false
	_edge_action = action
	_edge_frame = Engine.get_physics_frames()
	Input.action_press(action)


## Let go of a fired edge, but only once a physics frame has actually gone by —
## `body.gd` reads these with `is_action_just_pressed()` inside
## `_physics_process`, and `_process` can run more often than physics does, so
## releasing in the same tick would hide the press completely.
func _release_edges() -> void:
	if _edge_action == &"":
		return
	if Engine.get_physics_frames() <= _edge_frame:
		return
	Input.action_release(_edge_action)
	_edge_action = &""


func _press(action: StringName, strength: float) -> void:
	if strength <= 0.0:
		if Input.is_action_pressed(action):
			Input.action_release(action)
		return
	Input.action_press(action, strength)


func _release_all() -> void:
	for action in [&"move_left", &"move_right"]:
		if Input.is_action_pressed(action):
			Input.action_release(action)
	if _edge_action != &"":
		Input.action_release(_edge_action)
		_edge_action = &""


## Ring where the finger landed, knob where it is now. Palette colours so it
## belongs to the game rather than looking like engine debug UI.
func _on_draw() -> void:
	if _touch_index == -1:
		return
	var knob: Vector2 = _origin + _offset.limit_length(max_radius)
	_draw.draw_circle(_origin, max_radius, Color(Colors.OUTLINE, 0.22))
	_draw.draw_arc(_origin, max_radius, 0.0, TAU, 32, Color(Colors.BONE, 0.35), 2.0, true)
	_draw.draw_circle(knob, 13.0, Color(Colors.BONE, 0.55))
	_draw.draw_arc(knob, 13.0, 0.0, TAU, 24, Color(Colors.OUTLINE, 0.5), 2.0, true)
