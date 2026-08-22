extends Node2D
## Kikis orbiting the head. `pressure` 0–1: 0 = shoved off (satisfy both
## needs), 1 = touching the head (`DayManager.fail("kiki")`). Creep starts
## only after `begin()` so the walk-up is safe.
##
## Sprites come from kiki_frames.tres (lil_kiki / big_kiki). AnimatedSprite2D
## at 2× like the rest of the art. A StaticBody2D circle matches the ring so
## the body cannot walk through to the head (gaps between sprites would leak).
## Docs: https://docs.godotengine.org/en/stable/classes/class_animatedsprite2d.html

signal pressure_changed(value: float)

@export var frames: SpriteFrames
@export var start_pressure: float = 0.5
@export var mash_gain: float = 0.07
@export var creep_rate: float = 0.12
@export var near_radius: float = 22.0
@export var far_radius: float = 180.0
@export var lil_count: int = 5
@export var big_count: int = 2

@onready var body_need: WinCondition = $BodyNeed
@onready var mind_need: WinCondition = $MindNeed

var pressure: float = 0.5
var _live: bool = false
var _ended: bool = false
var _kikis: Array[AnimatedSprite2D] = []
var _base_angles: Array[float] = []
var _block_shape: CircleShape2D
var _block_col: CollisionShape2D


func _ready() -> void:
	body_need.key = "body"
	mind_need.key = "mind"
	pressure = clampf(start_pressure, 0.05, 0.95)
	_make_block()
	_spawn()
	_layout()
	set_process(true)


func _make_block() -> void:
	# StaticBody2D: solid to CharacterBody2D, no physics of its own.
	var wall: StaticBody2D = StaticBody2D.new()
	_block_shape = CircleShape2D.new()
	_block_col = CollisionShape2D.new()
	_block_col.shape = _block_shape
	wall.add_child(_block_col)
	add_child(wall)


func begin() -> void:
	if _ended:
		return
	_live = true


func push() -> void:
	if not _live or _ended:
		return
	_set_pressure(pressure - mash_gain)


func _process(delta: float) -> void:
	if _live and not _ended:
		_set_pressure(pressure + creep_rate * delta)
	_layout()


func _spawn() -> void:
	if frames == null:
		push_warning("KikiSwarm: no SpriteFrames assigned.")
		return
	var total: int = lil_count + big_count
	for i in total:
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.sprite_frames = frames
		sprite.scale = Vector2(2.0, 2.0)
		var is_big: bool = i >= lil_count
		if is_big and frames.has_animation(&"big_kiki"):
			sprite.play(&"big_kiki")
		elif frames.has_animation(&"lil_kiki"):
			sprite.play(&"lil_kiki")
		add_child(sprite)
		_kikis.append(sprite)
		_base_angles.append(TAU * float(i) / float(maxi(total, 1)))


func _layout() -> void:
	var t: float = clampf(pressure, 0.0, 1.0)
	var radius: float = lerpf(far_radius, near_radius, t)
	var fade: float = clampf(t * 1.4, 0.0, 1.0)
	for i in _kikis.size():
		var sprite: AnimatedSprite2D = _kikis[i]
		var angle: float = _base_angles[i]
		sprite.position = Vector2(cos(angle), sin(angle)) * radius
		sprite.modulate.a = fade
		sprite.visible = t > 0.02
	if _block_shape != null:
		_block_shape.radius = radius
	if _block_col != null:
		_block_col.disabled = _ended or t <= 0.02


func _set_pressure(next: float) -> void:
	if _ended:
		return
	pressure = clampf(next, 0.0, 1.0)
	pressure_changed.emit(pressure)
	var head: Node = get_tree().get_first_node_in_group("head")
	if head != null and head.has_method("set_agitation"):
		head.call("set_agitation", 1.0 + pressure * 3.0)
	if pressure <= 0.0:
		_win()
	elif pressure >= 1.0:
		_fail()


func _win() -> void:
	_ended = true
	_live = false
	pressure = 0.0
	_layout()
	mind_need.satisfy()
	body_need.satisfy()


func _fail() -> void:
	_ended = true
	_live = false
	var manager: Node = get_tree().get_first_node_in_group("day_manager")
	if manager != null and manager.has_method("fail"):
		manager.call("fail", "kiki")
