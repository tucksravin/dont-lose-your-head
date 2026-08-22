class_name KikiCloud
extends Node2D
## A ring of intrusive thoughts around the head. Radius follows the day's
## PanicCounter: 0 panic = far / faded, max panic = tight on the skull.
##
## Visual only — PanicCounter already fails at max. No collision, so this
## does not fight the stand-still day or the walk to the cage button.
##
## Spawns via `Kiki.spawn` so every thought scrambles its frame and rotation
## (Tucker's kiki rule). A Node2D (not Area2D) because we only place sprites.
## Docs: https://docs.godotengine.org/en/stable/classes/class_node2d.html

@export var lil_count: int = 10
@export var big_count: int = 4
## Radius at 0 panic (px from the head).
@export var far_radius: float = 170.0
## Radius at max panic (px from the head).
@export var near_radius: float = 36.0
## How fast the cloud turns (rad/s). Cosmetic — it is not a timer.
@export var orbit_speed: float = 0.4
## Don't draw kikis below this world y, so a floor-level head does not bury them.
@export var floor_y: float = 304.0

var _kikis: Array[Kiki] = []
var _base_angles: Array[float] = []
var _radii: Array[float] = []
var _head: Node2D
var _counter: PanicCounter
var _orbit: float = 0.0


func _ready() -> void:
	z_index = 2
	_head = get_tree().get_first_node_in_group("head") as Node2D
	_counter = get_tree().get_first_node_in_group("panic_counter") as PanicCounter
	if _counter == null:
		push_warning("KikiCloud: no PanicCounter in the tree — cloud stays at far_radius.")
	_spawn()
	_layout()


func _process(delta: float) -> void:
	_orbit += orbit_speed * delta
	_layout()


func _spawn() -> void:
	var total: int = lil_count + big_count
	for i in total:
		var kind: StringName = &"big_kiki" if i >= lil_count else &"lil_kiki"
		var kiki: Kiki = Kiki.spawn(self, kind, Vector2.ZERO)
		_kikis.append(kiki)
		_base_angles.append(TAU * float(i) / float(maxi(total, 1)) + randf_range(-0.2, 0.2))
		_radii.append(randf_range(0.82, 1.18))


func _layout() -> void:
	if _head != null:
		global_position = _head.global_position
	var t: float = 0.0
	if _counter != null:
		t = _counter.ratio()
	var radius: float = lerpf(far_radius, near_radius, t)
	var fade: float = clampf(t * 1.6, 0.0, 1.0)
	for i in _kikis.size():
		var kiki: Kiki = _kikis[i]
		var angle: float = _base_angles[i] + _orbit
		var pos: Vector2 = Vector2(cos(angle), sin(angle)) * radius * _radii[i]
		var world_y: float = global_position.y + pos.y
		if world_y > floor_y:
			pos.y -= world_y - floor_y
		kiki.position = pos
		kiki.modulate.a = fade
		kiki.visible = fade > 0.04
