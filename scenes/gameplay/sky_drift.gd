extends Polygon2D
## Sky drift — the backdrop darkens as the day runs out. Attach to a day's
## `Background` Polygon2D; it finds the scene's Sun and lerps its own colour
## from `dawn` to `dusk` by Sun.progress(). Deliberately off-palette in
## between (Tucker OK'd the drift Fri night): the two ends are palette stops,
## the journey isn't. Set `steps` > 0 to quantise the drift into that many
## palette-ish plateaus instead of a smooth ramp.

@export var dawn: Color = Color("988277")
@export var dusk: Color = Color("645543")
## 0 = smooth. N = snap to N discrete colours between dawn and dusk.
@export var steps: int = 0

var _sun: Node


func _ready() -> void:
	color = dawn
	var root: Node = owner if owner != null else get_parent()
	for n in root.find_children("*", "Node2D", true, false):
		if n.has_method("progress") and n.has_signal("sunset"):
			_sun = n
			break
	if _sun == null:
		push_warning("SkyDrift: no Sun in '%s' — sky stays at dawn." % root.name)
		set_process(false)


func _process(_delta: float) -> void:
	var t: float = float(_sun.call("progress"))
	if steps > 0:
		t = floorf(t * steps) / steps
	color = dawn.lerp(dusk, t)
