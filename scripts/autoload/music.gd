extends Node
## Music per scene (autoload: `Music`). Plays `res://assets/audio/music/<track>.ogg`
## for whatever scene is current, crossfading on change, and stays silent for a
## track that has no file yet — same contract as Sfx.
##
## Which track a scene wants, in order: a `music_track` property on the scene's
## root script (`@export var music_track: StringName = &"spooky"`), else the
## entry for its path in TRACKS, else — for anything under scenes/days/ — the
## generic "day" track, else silence. So per-day music is an export on the day;
## one shared loop is one file named day.ogg; and nothing at all is fine too.
##
## One AudioStreamPlayer per "side" of the crossfade, on the Music bus.
## Ogg Vorbis loops are switched on at runtime (AudioStreamOggVorbis.loop), so
## nobody has to remember the Import-dock checkbox.
## Web note: audio can't start before the first click/keypress; a track that
## wanted to start earlier begins at the first input instead (Godot retries).

const TRACKS: Dictionary = {
	"res://scenes/intro/intro.tscn": &"intro",
	"res://scenes/reunion/reunion.tscn": &"reunion",
	"res://scenes/transition/transition.tscn": &"transition",
	"res://scenes/transition/transition_cage.tscn": &"transition",
}
const GENERIC_DAY_TRACK: StringName = &"day"

## Emitted when the track changes (StringName, may be empty for silence).
signal track_changed(track: StringName)

@export var crossfade: float = 0.8
@export var volume_db: float = -6.0

var current_track: StringName = &""
var _scene_path: String = ""
var _a: AudioStreamPlayer
var _b: AudioStreamPlayer
var _front: AudioStreamPlayer  # the one currently audible
var _fade: Tween


func _ready() -> void:
	_a = _make_player()
	_b = _make_player()
	_front = _a


func _process(_delta: float) -> void:
	var scene: Node = get_tree().current_scene
	var path: String = scene.scene_file_path if scene != null else ""
	if path == _scene_path:
		return
	_scene_path = path
	_switch_to(_track_for(scene))


## What a scene wants to hear. Public so tests and the overlay can ask.
func _track_for(scene: Node) -> StringName:
	if scene == null:
		return &""
	if "music_track" in scene:
		var t: StringName = StringName(str(scene.get("music_track")))
		if not t.is_empty():
			return t
	var path: String = scene.scene_file_path
	if TRACKS.has(path):
		return TRACKS[path]
	if path.begins_with("res://scenes/days/"):
		return GENERIC_DAY_TRACK
	return &""


func _switch_to(track: StringName) -> void:
	if track == current_track:
		return
	current_track = track
	track_changed.emit(track)
	var stream: AudioStream = _load_track(track)
	var back: AudioStreamPlayer = _b if _front == _a else _a
	if _fade != null and _fade.is_valid():
		_fade.kill()
	if not _front.playing and stream == null:
		return  # silence → silence: nothing to fade (a Tween with no tweeners is an error)
	_fade = create_tween().set_parallel(true)
	if _front.playing:
		_fade.tween_property(_front, "volume_db", -40.0, crossfade)
		_fade.chain().tween_callback(_front.stop)
	if stream != null:
		back.stream = stream
		back.volume_db = -40.0
		back.play()
		_fade.tween_property(back, "volume_db", volume_db, crossfade)
	_front = back


func _load_track(track: StringName) -> AudioStream:
	if track.is_empty():
		return null
	var path: String = "res://assets/audio/music/%s.ogg" % track
	if not ResourceLoader.exists(path):
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream


func _make_player() -> AudioStreamPlayer:
	var p: AudioStreamPlayer = AudioStreamPlayer.new()
	p.bus = &"Music"
	p.volume_db = volume_db
	add_child(p)
	return p
