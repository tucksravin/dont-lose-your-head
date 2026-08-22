extends Node2D
## Lockdown's WarioWare setup beat, then the dodge-and-answer puzzle.
##
## Sequence (smahr, Sat 10:56): head waits alone in the middle → interact
## picks it up, a bar blocks the right exit, a pedestal opens → interact with
## the pedestal seats the head → pads and thought-rain start.
##
## Lives on the day root rather than a DayManager subclass because none of this
## is a win-condition hook — it happens *before* the needs. DayManager still
## owns fail / release / next_day.
##
## Carry is scripted (`global_position` follow), not a physics joint: the head
## stays a frozen RigidBody2D (DESIGN §2.1) and we turn its collision off so it
## doesn't shove the body. Same `interact` action as the reunion and the pads.
## Docs: https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html

enum Phase { FIND_HEAD, PLACE_HEAD, PUZZLE }

@export var interact_distance: float = 56.0
@export var carry_offset: Vector2 = Vector2(12.0, -40.0)
@export var pedestal_open_time: float = 0.25
@export var tip_time: float = 0.5
@export var find_text: String = "Walk to the head and press E."
@export var place_text: String = "The way out is blocked. Set the head on the pedestal (E)."
@export var puzzle_text: String = "Dodge the thoughts. Stand on an answer and press E."

@onready var body: CharacterBody2D = $Body
@onready var head: Head = $Head
@onready var instruction: Label = $Instruction
@onready var interact_prompt: Label = $InteractPrompt
@onready var exit_bar: StaticBody2D = $ExitBar
@onready var exit_bar_shape: CollisionShape2D = $ExitBar/CollisionShape2D
@onready var pedestal: Node2D = $Pedestal
@onready var pedestal_visual: ColorRect = $Pedestal/Visual
@onready var pedestal_area: Area2D = $Pedestal/Area
@onready var mount: Marker2D = $Pedestal/Mount
@onready var puzzle_chain: Node2D = $PuzzleChain
@onready var thought_rain: Node2D = $ThoughtRain

var _phase: Phase = Phase.FIND_HEAD
var _carrying: bool = false
var _on_pedestal: bool = false
var _pedestal_open: bool = false


func _ready() -> void:
	instruction.text = find_text
	interact_prompt.visible = false
	_set_head_solid(true)
	_set_exit_blocked(false)
	_set_pads_enabled(false)
	pedestal.visible = false
	pedestal_area.monitoring = false
	pedestal_area.body_entered.connect(_on_pedestal_entered)
	pedestal_area.body_exited.connect(_on_pedestal_exited)
	head.released.connect(_on_head_released)
	Events.day_completed.connect(_on_day_completed)


func _physics_process(_delta: float) -> void:
	if _carrying:
		head.global_position = body.global_position + _carry_offset()
	match _phase:
		Phase.FIND_HEAD:
			_poll_head_interact()
		Phase.PLACE_HEAD:
			_poll_pedestal_interact()
		Phase.PUZZLE:
			interact_prompt.visible = false


func _carry_offset() -> Vector2:
	var sprite: AnimatedSprite2D = body.get_node_or_null("Visual") as AnimatedSprite2D
	var facing: float = -1.0 if sprite != null and sprite.flip_h else 1.0
	return Vector2(carry_offset.x * facing, carry_offset.y)


func _poll_head_interact() -> void:
	var in_range: bool = body.global_position.distance_to(head.global_position) < interact_distance
	interact_prompt.visible = in_range
	if in_range:
		interact_prompt.global_position = head.global_position + Vector2(-8.0, -36.0)
	if in_range and Input.is_action_just_pressed("interact"):
		_pick_up_head()


func _poll_pedestal_interact() -> void:
	interact_prompt.visible = _on_pedestal and _pedestal_open
	if interact_prompt.visible:
		interact_prompt.global_position = pedestal.global_position + Vector2(-8.0, -72.0)
	if _on_pedestal and _pedestal_open and Input.is_action_just_pressed("interact"):
		_place_head()


func _pick_up_head() -> void:
	_carrying = true
	_set_head_solid(false)
	_set_exit_blocked(true)
	_open_pedestal()
	_phase = Phase.PLACE_HEAD
	instruction.text = place_text
	interact_prompt.visible = false


func _open_pedestal() -> void:
	pedestal.visible = true
	var closed_top: float = pedestal_visual.offset_bottom
	pedestal_visual.offset_top = closed_top
	var tw: Tween = create_tween()
	tw.tween_property(pedestal_visual, "offset_top", -48.0, pedestal_open_time)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		_pedestal_open = true
		pedestal_area.monitoring = true
		call_deferred("_sync_pedestal_occupation")
	)


func _place_head() -> void:
	if not _carrying:
		return
	_carrying = false
	_phase = Phase.PUZZLE
	head.global_position = mount.global_position
	_set_head_solid(true)
	interact_prompt.visible = false
	instruction.text = puzzle_text
	_set_pads_enabled(true)
	if puzzle_chain.has_method("start"):
		puzzle_chain.call("start")
	if thought_rain.has_method("begin"):
		thought_rain.call("begin")


## DayManager awaits this after the needs are met, before head.release().
## Reparent the head onto the mount so it rides the fall, tween the pedestal
## +90° (Godot 2D: Y-down, positive rotation is clockwise, so the top falls
## toward +X / the exit), then put the head back on the day so the scripted
## roll is in world space. Docs: https://docs.godotengine.org/en/stable/tutorials/math/vectors_advanced.html#rotation
func _before_head_release() -> void:
	if _phase != Phase.PUZZLE:
		return
	_carrying = false
	_set_head_solid(false)
	pedestal_area.monitoring = false
	_reparent_keep_global(head, mount)
	head.position = Vector2.ZERO
	var tw: Tween = create_tween()
	tw.tween_property(pedestal, "rotation", PI / 2.0, tip_time)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tw.finished
	if not is_instance_valid(head):
		return
	_reparent_keep_global(head, self)
	head.global_position.y = 306.0


func _reparent_keep_global(node: Node2D, new_parent: Node) -> void:
	var g: Transform2D = node.global_transform
	var old: Node = node.get_parent()
	if old == new_parent:
		return
	if old != null:
		old.remove_child(node)
	new_parent.add_child(node)
	node.global_transform = g


func _on_pedestal_entered(other: Node2D) -> void:
	if other is CharacterBody2D:
		_on_pedestal = true


func _on_pedestal_exited(other: Node2D) -> void:
	if other is CharacterBody2D:
		_on_pedestal = false


func _sync_pedestal_occupation() -> void:
	_on_pedestal = false
	if not pedestal_area.monitoring:
		return
	for other in pedestal_area.get_overlapping_bodies():
		if other is CharacterBody2D:
			_on_pedestal = true
			break


func _on_head_released() -> void:
	_carrying = false
	_set_exit_blocked(false)


func _on_day_completed() -> void:
	_set_exit_blocked(false)


func _set_exit_blocked(blocked: bool) -> void:
	exit_bar.visible = blocked
	exit_bar_shape.disabled = not blocked


func _set_head_solid(solid: bool) -> void:
	var shape: CollisionShape2D = head.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.disabled = not solid


func _set_pads_enabled(on: bool) -> void:
	for node in get_tree().get_nodes_in_group("answer_pad"):
		if node.has_method("set_enabled"):
			node.call("set_enabled", on)
