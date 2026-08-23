extends CanvasLayer
class_name VisionBlur
## A real screen-space blur with a small sharp circle on the body and,
## when a head is in the scene, another on the skull. The rest of the
## room stays unreadably blurred. Lifts once a chosen WinCondition key
## is met (Velma: the glasses hitting the head — `mind`).
##
## Godot has no ready-made "attach a blur" resource; this is a canvas_item
## screen-reading shader (vision_blur.gdshader) that reads SCREEN_TEXTURE at
## a high mip level for a cheap, real blur — no hand-written kernel needed.
## Checked against this project's Compatibility renderer's known
## screen-texture bugs before using it: dimming when glow/tonemap is also
## enabled, and black-out if another shader reads hint_depth_texture and the
## window resizes — this project has neither, so it's safe here.
## Docs: https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html
##
## The mask (clear circle vs. blurred) is computed in the shader from the
## rect's own local VERTEX position, not from a CPU-side transform — that
## stays correct under this project's window/stretch/mode = "canvas_items"
## without this script needing to know about it. See the shader's header
## comment for why that's the robust way to do it here.

## Which need lifts the blur when satisfied.
@export_enum("body", "mind") var lift_on_key: String = "mind"
## Radius (px, world/canvas space) of the sharp circle around the body.
@export var clear_radius: float = 55.0
## Sharp circle around the head. 0 = body only.
@export var head_clear_radius: float = 50.0
## Width (px, world/canvas space) of the sharp-to-blurred transition band —
## narrow, so the circle reads as a defined edge, not a long gentle fade.
@export var edge_softness: float = 20.0
## Mip level sampled for the blurred pass — higher reads a blurrier mip. 6 is
## deep enough into the chain that shapes outside the circle stop being
## readable, not just softened.
@export_range(0.0, 8.0) var blur_strength: float = 6.0
## Seconds for the blur to fade out once the day lifts it.
@export var fade_duration: float = 0.6
## Optional twist (docs/days/velma-plan.md §4.3 — cut this and the two lines
## that use it if dropped): shrinks the clear radius further, up to this many
## extra px, scaled by how fast the body is moving. Smaller than before now
## that clear_radius itself is small — this only trims it, doesn't erase it.
@export var speed_penalty_radius: float = 15.0
@export var speed_penalty_at_speed: float = 150.0  ## body.gd's default `speed`

@onready var _rect: ColorRect = $Fog
@onready var _material: ShaderMaterial = ShaderMaterial.new()

var _body: CharacterBody2D
var _head: Node2D
var _lifted: bool = false
var _radius: float = 55.0


func _ready() -> void:
	_radius = clear_radius
	_material.shader = preload("res://scenes/gameplay/vision_blur.gdshader")
	_material.set_shader_parameter("edge_softness_px", edge_softness)
	_material.set_shader_parameter("blur_lod", blur_strength)
	_rect.material = _material
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D
	_head = get_tree().get_first_node_in_group("head") as Node2D
	if _body == null:
		push_warning("VisionBlur: no node in group 'body' — blur stays screen-centred.")
		_apply(Vector2(320, 180), _radius)
	else:
		_apply(_body.global_position, _radius)
	Events.condition_satisfied.connect(_on_condition_satisfied)


func _process(_delta: float) -> void:
	if _lifted or _body == null:
		return
	var radius: float = _radius
	if speed_penalty_radius > 0.0:
		var t: float = clampf(_body.velocity.length() / speed_penalty_at_speed, 0.0, 1.0)
		radius -= speed_penalty_radius * t
	_apply(_body.global_position, radius)


func _apply(center_px: Vector2, radius_px: float) -> void:
	_material.set_shader_parameter("clear_center", center_px)
	_material.set_shader_parameter("clear_radius_px", radius_px)
	if _head != null and head_clear_radius > 0.0:
		_material.set_shader_parameter("clear_center_b", _head.global_position)
		_material.set_shader_parameter("clear_radius_b_px", head_clear_radius)
	else:
		_material.set_shader_parameter("clear_radius_b_px", 0.0)


func _on_condition_satisfied(key: String) -> void:
	if key != lift_on_key or _lifted:
		return
	_lifted = true
	set_process(false)
	var tween: Tween = create_tween()
	tween.tween_method(_set_fade, 1.0, 0.0, fade_duration)


func _set_fade(value: float) -> void:
	_material.set_shader_parameter("fade", value)
