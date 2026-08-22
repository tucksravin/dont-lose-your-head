class_name Kiki
extends AnimatedSprite2D
## One kiki — an intrusive thought (kikis.png, Tucker's; violet ramp). Two
## kinds, `lil_kiki` (9 frames) and `big_kiki` (12), both 10 fps loops in
## kiki_frames.tres. Every kiki **scrambles itself on _ready()**: a random start
## frame (plus a random sub-frame phase, so two on the same frame still drift
## apart) and a random right-angle rotation — 0/90/180/270° — so no two in a
## scene look the same (decided Sat, Tucker: "they start on a random frame and
## random 90 degree rotation so none of them looks the same").
##
## Two ways to get one:
##   - in the editor: drag scenes/gameplay/kiki.tscn into a scene, pick `kind`
##     in the Inspector (scene instancing — the idiomatic way to place props);
##   - from code:  Kiki.spawn(self, &"big_kiki", Vector2(320, 90))
##     which builds one, adds it under `self`, and returns it. `Kiki.make()` is
##     the same without the add_child.
## Both give a plain AnimatedSprite2D (scale 2 — DESIGN: render at integer 2×),
## so position/modulate/z_index/etc. work as usual; `scramble()` re-rolls.
##
## Why a class_name with static factories instead of an autoload: there is no
## state to hold, and `Kiki.spawn(...)` reads like what it does. Why not
## preload kiki.tscn inside this script: the scene references this script, so
## that would be a resource cycle — `make()` builds the node in code instead.
## Docs: https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html

const FRAMES: SpriteFrames = preload("res://assets/sprites/kiki_frames.tres")
## The two animation names in kiki_frames.tres.
const KINDS: Array[StringName] = [&"lil_kiki", &"big_kiki"]
## On-screen scale for every kiki (integer multiple of the 16 px art).
const PIXEL_SCALE: Vector2 = Vector2(2.0, 2.0)

## Which kiki this is — one of KINDS.
@export_enum("lil_kiki", "big_kiki") var kind: String = "lil_kiki":
	set(value):
		kind = value
		if is_node_ready():
			_apply_kind()
## Re-roll frame and rotation on _ready(). Off = keep whatever the editor saved.
@export var scramble_on_ready: bool = true


## Build a kiki (not in the tree yet). `kind` is &"lil_kiki" or &"big_kiki";
## anything else falls back to lil with a warning.
static func make(which: StringName = &"lil_kiki", at: Vector2 = Vector2.ZERO) -> Kiki:
	var kiki: Kiki = Kiki.new()
	kiki.sprite_frames = FRAMES
	kiki.scale = PIXEL_SCALE
	if which in KINDS:
		kiki.kind = String(which)
	else:
		push_warning("Kiki.make: unknown kind '%s' — using lil_kiki." % which)
	kiki.position = at
	return kiki


## make() + add it under `parent`. Returns the kiki so the caller can keep it.
static func spawn(parent: Node, which: StringName = &"lil_kiki", at: Vector2 = Vector2.ZERO) -> Kiki:
	var kiki: Kiki = make(which, at)
	parent.add_child(kiki)
	return kiki


func _ready() -> void:
	if sprite_frames == null:
		sprite_frames = FRAMES
	_apply_kind()
	if scramble_on_ready:
		scramble()


## Random start frame + sub-frame phase, random right-angle rotation.
func scramble() -> void:
	var anim: StringName = StringName(kind)
	var count: int = sprite_frames.get_frame_count(anim) if sprite_frames != null else 0
	if count > 0:
		set_frame_and_progress(randi() % count, randf())
	rotation_degrees = 90.0 * float(randi() % 4)


func _apply_kind() -> void:
	var anim: StringName = StringName(kind)
	if sprite_frames != null and sprite_frames.has_animation(anim):
		play(anim)
	else:
		push_warning("Kiki: kiki_frames.tres has no animation '%s'." % anim)
