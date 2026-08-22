extends Node
## Sound effects by name (autoload: `Sfx`). `Sfx.play(&"jump")` — that's the API.
##
## Every cue the game can make is declared in CUES below, with what it is for.
## A cue plays `res://assets/audio/sfx/<cue>.wav` (or .ogg) if that file
## exists and is silent otherwise — so the game is fully wired before a single
## sound exists, and dropping a file in is all it takes to hear it. At boot it
## prints one line listing the cues that have no file yet: that list IS the
## to-record list (also in assets/audio/README.md).
##
## Who calls play(): mostly nobody by hand. This node listens to the signals
## the game already emits — the Events bus, plus the body/head/sun/panic nodes
## as they enter the tree (`SceneTree.node_added`, once, here) — and maps them
## to cues. Gameplay scripts stay free of audio knowledge; a new day gets its
## sounds by using the same signals everything else uses. A scene with a
## one-off sound (the reunion dive) calls Sfx.play() directly, which is the
## normal Godot idiom for autoloads.
##
## Godot bits: AudioStreamPlayer (non-positional — 2D panning is noise at this
## screen size) · a small pool so overlapping cues don't cut each other off ·
## the "SFX" bus from default_bus_layout.tres so music and effects can be mixed
## separately. Docs: https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html
##
## Web: browsers refuse to start audio until the page has had a click/keypress.
## Godot queues nothing — cues fired before the first input are just lost. The
## intro plays hands-free (the head runs off on its own), so on the web the
## intro is silent and sound starts with the first keypress in day 1 — a
## title / press-any-key screen (TASKS X4) would move that earlier.

## cue → what it is for. Keep this the single source of truth.
const CUES: Dictionary = {
	&"land": "body touches down after a jump or fall",
	&"step": "optional footstep; fires from the walk cycle only if a file exists",
	&"need_met": "one of the day's two needs just got satisfied (body or mind)",
	&"day_won": "both needs met — the head is released",
	&"head_roll": "the head starts rolling away (release) — a short roll/rattle, not a loop",
	&"day_failed": "the day is lost (sunset, pit, panic maxed) — the restart sting",
	&"sunset_warning": "the sun is low (last ~5 s of the day) — a tick/ambience swell, once",
	&"panic_tick": "the panic meter changed by one — a heartbeat tick; rate follows the meter",
	&"calm": "panic reached zero",
	&"bridge_drop": "the bridge falls into place (platforming day)",
	&"dive": "the body leaps for the head (reunion)",
	&"reunite": "the body lands on the head (reunion)",
	&"cage": "a cage drops onto the head (transition)",
	&"thud": "the head stops rolling on the slope (transition)",
	&"ui_confirm": "button press / retry",
}

## Emitted every time a cue is requested (whether or not a file exists). The
## smoke tests listen to this; the debug overlay could too.
signal played(cue: StringName)

## Tunables. Plain vars, not @export: an autoload has no scene and no
## Inspector, so there is nowhere else to edit these — change them here.
## How many cues can overlap before the oldest is cut. 6 is plenty for a jam.
var voices: int = 6
## Seconds before sunset at which "sunset_warning" fires.
var sunset_warning_lead: float = 5.0

var _streams: Dictionary = { } # cue → AudioStream (only cues that have a file)
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _missing: Array[StringName] = []


func _ready() -> void:
	for i in voices:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_players.append(p)
	for cue in CUES:
		var stream: AudioStream = _load_cue(cue)
		if stream != null:
			_streams[cue] = stream
		else:
			_missing.append(cue)
	if not _missing.is_empty():
		print(
			"Sfx: %d/%d cues have no file yet — see assets/audio/README.md: %s"
			% [_missing.size(), CUES.size(), ", ".join(_missing)]
		)

	# DayManager / WinConditionManager emit these on the bus so Sfx doesn't
	# double-play by also hooking their local signals.
	Events.condition_satisfied.connect(
		func(_key: String) -> void:
			play(&"need_met"),
	)
	Events.day_completed.connect(
		func() -> void:
			play(&"day_won"),
	)
	Events.day_failed.connect(
		func(_reason: String) -> void:
			play(&"day_failed"),
	)
	get_tree().node_added.connect(_on_node_added)


## Play a cue. Unknown cue names are a push_warning (a typo, not a crash);
## known cues with no file are silent. Returns true if something actually played.
func play(cue: StringName, pitch_scale: float = 1.0) -> bool:
	if not CUES.has(cue):
		push_warning("Sfx: unknown cue '%s' — add it to Sfx.CUES" % cue)
		return false
	played.emit(cue)
	if not _streams.has(cue):
		return false
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = _streams[cue]
	p.pitch_scale = pitch_scale
	p.play()
	return true


## Cues declared but without a file — the to-record list.
func missing() -> Array[StringName]:
	return _missing.duplicate()


func has_file(cue: StringName) -> bool:
	return _streams.has(cue)


## Wire up sound-making nodes as they appear, by the signals they carry — no
## hard node paths, no per-scene setup. node_added fires before the node's
## _ready, so groups aren't set yet; match on signals/methods instead.
func _on_node_added(node: Node) -> void:
	if node is CharacterBody2D and node.has_signal("jumped") and node.has_signal("landed"):
		# jumped is body.gd's own local sound now (jump_sounds/_jump_sound) —
		# only landed is still a global cue here.
		node.connect(
			"landed",
			func() -> void:
				play(&"land"),
		)
	elif node.has_signal("released") and node.has_signal("left_scene"):
		node.connect(
			"released",
			func() -> void:
				play(&"head_roll"),
		)
	elif node.has_signal("sunset") and "day_length" in node:
		# Wait for _ready so day_length is final, then arm a one-shot warning.
		node.ready.connect(
			func() -> void:
				_arm_sunset_warning(node),
			CONNECT_ONE_SHOT,
		)
	elif node.has_signal("panic_changed") and node.has_signal("calmed"):
		node.connect("panic_changed", _on_panic_changed)
		node.connect(
			"calmed",
			func() -> void:
				play(&"calm"),
		)


func _arm_sunset_warning(sun: Node) -> void:
	var lead: float = maxf(float(sun.get("day_length")) - sunset_warning_lead, 0.0)
	var timer: SceneTreeTimer = get_tree().create_timer(lead)
	# Capture the id, not the node: a day that ends early frees its Sun before
	# this fires, and a lambda holding a freed Node is an engine error on call.
	var sun_id: int = sun.get_instance_id()
	timer.timeout.connect(
		func() -> void:
			var live: Object = instance_from_id(sun_id)
			if live is Node and (live as Node).is_inside_tree():
				play(&"sunset_warning"),
	)


func _on_panic_changed(value: int) -> void:
	# A heartbeat that tightens as panic climbs: higher pitch at higher panic.
	play(&"panic_tick", 0.8 + 0.4 * clampf(value / 30.0, 0.0, 1.0))


func _load_cue(cue: StringName) -> AudioStream:
	for ext in ["wav", "ogg"]:
		var path: String = "res://assets/audio/sfx/%s.%s" % [cue, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null
