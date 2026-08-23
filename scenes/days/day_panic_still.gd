extends Node2D
## First panic day: stand still until the meter hits 0. The head is stuck in
## a tree on the right-edge cliff (not caged — the cage comes after the
## fall, in transition_cage). When it calms it sighs (wink + squash) and
## falls backward out of the canopy and off the drop.
##
## `_before_head_release` is the DayManager hook (same as lockdown's tip and
## the hanging-cage drop): it runs after the needs are met and before
## `head.release()`. A Tween moves the frozen RigidBody2D; we never unfreeze
## it. Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html

@export var sigh_time: float = 0.55
@export var fall_time: float = 0.9
## Off the right *and* below the 360 floor, past Head.exit_margin 64.
@export var fall_end: Vector2 = Vector2(720.0, 460.0)
## Clockwise tip — looking at the body (left), this is falling backward.
@export var fall_spin: float = 2.6
@export var instruction_text: String = "Hold still. Panic to zero — your head sighs and falls out of the tree."

@onready var head: Head = $Head
@onready var pit: Area2D = $Pit
@onready var instruction: Label = $Instruction


func _ready() -> void:
	instruction.text = instruction_text
	if pit != null:
		pit.body_entered.connect(_on_pit)


func _on_pit(other: Node2D) -> void:
	if other is CharacterBody2D:
		var manager: Node = get_tree().get_first_node_in_group("day_manager")
		if manager != null and manager.has_method("fail"):
			manager.call("fail", "pit")


## Look at the body, sigh, then tip backward out of the tree.
func _before_head_release() -> void:
	if head == null:
		return
	head.look(-1)
	head.set_solid(false)
	var visual: AnimatedSprite2D = head.get_node_or_null("Visual") as AnimatedSprite2D
	if visual != null:
		var wink: StringName = &"wink_glasses" if Game.wearing_glasses else &"wink"
		if visual.sprite_frames != null and visual.sprite_frames.has_animation(wink):
			visual.play(wink)
		var rest: Vector2 = visual.scale
		var sigh: Tween = create_tween()
		sigh.tween_property(visual, "scale", Vector2(rest.x * 1.15, rest.y * 0.78), sigh_time * 0.45)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		sigh.tween_property(visual, "scale", rest, sigh_time * 0.55)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await sigh.finished
	else:
		await get_tree().create_timer(sigh_time).timeout
	if not is_instance_valid(head):
		return
	# The branch gives way (tree.png, Tucker's: whole → 3 frames of breaking),
	# then the head falls. One-shot: it holds on the broken stub afterwards.
	var tree_visual: AnimatedSprite2D = get_node_or_null("Tree/Visual") as AnimatedSprite2D
	if tree_visual != null and tree_visual.sprite_frames != null \
			and tree_visual.sprite_frames.has_animation(&"breaking"):
		tree_visual.play(&"breaking")
	var fall: Tween = create_tween()
	fall.set_parallel(true)
	fall.tween_property(head, "global_position", fall_end, fall_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_property(head, "rotation", fall_spin, fall_time)
	await fall.finished
