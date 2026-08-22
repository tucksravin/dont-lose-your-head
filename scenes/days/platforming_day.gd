extends Node2D
## Platforming day: ride platforms, stomp the kiki over the spike-pit
## button, bridge swings down, the head's perch tips and dumps it.
##
## Stomp the kiki: it falls onto the button and that satisfies body + mind.
## The tilt/dump is `_before_head_release` on this root — DayManager awaits
## it, then `head.release()` rolls off. AnimatableBody2D for the rider:
## Godot moves it in the physics step so `move_and_slide` carries the body.
## Docs: https://docs.godotengine.org/en/stable/classes/class_animatablebody2d.html

@export var mover_left: float = 210.0
@export var mover_right: float = 460.0
@export var mover_period: float = 3.2
@export var bounce_velocity: float = -280.0
@export var bridge_time: float = 0.55
@export var tilt_time: float = 0.45
@export var dump_time: float = 0.5
@export var dump_end: Vector2 = Vector2(420.0, 306.0)
@export var kiki_drop_time: float = 0.35
@export var instruction_text: String = "Ride the moving platform. Bounce on the thought — it hits the button."

@onready var bridge: StaticBody2D = $Bridge
@onready var spikes: Area2D = $Spikes
@onready var button: Area2D = $Button
@onready var mover: AnimatableBody2D = $MovingPlatform
@onready var perch: StaticBody2D = $HeadPlatform
@onready var head: Head = $Head
@onready var bounce: Area2D = $BounceKiki
@onready var body_need: WinCondition = $BodyNeed
@onready var mind_need: WinCondition = $MindNeed
@onready var instruction: Label = $HUD/Instruction

var _pressed: bool = false
var _ride_t: float = 0.0


func _ready() -> void:
	instruction.text = instruction_text
	spikes.body_entered.connect(_on_spikes)
	if bounce != null:
		bounce.set("bounce_velocity", bounce_velocity)
		if bounce.has_signal("stomped"):
			bounce.connect("stomped", _on_kiki_stomped)
	if head != null:
		head.look(-1)
	if bridge != null:
		bridge.rotation = -PI / 2.0
		# Visual only while up — a StaticBody2D wall would sit on the ride.
		bridge.collision_layer = 0
		bridge.collision_mask = 0


func _physics_process(delta: float) -> void:
	if mover == null or _pressed:
		return
	_ride_t += delta
	var u: float = 0.5 + 0.5 * sin(_ride_t * TAU / mover_period)
	mover.position.x = lerpf(mover_left, mover_right, u)


func _on_spikes(other: Node2D) -> void:
	if other is CharacterBody2D:
		var manager: Node = get_tree().get_first_node_in_group("day_manager")
		if manager != null and manager.has_method("fail"):
			manager.call("fail", "spikes")


func _on_kiki_stomped() -> void:
	if _pressed or bounce == null or button == null:
		return
	var dest: Vector2 = button.global_position
	var drop: Tween = create_tween()
	drop.tween_property(bounce, "global_position", dest, kiki_drop_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await drop.finished
	_press()


func _press() -> void:
	if _pressed:
		return
	_pressed = true
	body_need.satisfy()
	mind_need.satisfy()


## Drawbridge slams, perch tips, head slides off onto the new floor.
func _before_head_release() -> void:
	if not _pressed:
		return
	var swing: Tween = create_tween()
	swing.tween_property(bridge, "rotation", 0.0, bridge_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await swing.finished
	if is_instance_valid(bridge):
		bridge.collision_layer = 1
		bridge.collision_mask = 1
	if not is_instance_valid(perch) or not is_instance_valid(head):
		return
	head.set_solid(false)
	var tilt: Tween = create_tween()
	tilt.set_parallel(true)
	tilt.tween_property(perch, "rotation", 0.7, tilt_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tilt.tween_property(head, "global_position", dump_end, dump_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tilt.tween_property(head, "rotation", 1.2, dump_time)
	await tilt.finished
