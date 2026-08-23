extends Area2D
class_name Glasses
## Velma pickup. Touching them satisfies the body need ("find them").
## The day then throws them at the head; `deliver()` satisfies mind
## ("they can see") and puts the glasses on the skull.
##
## Area2D rather than a body: only overlap detection is needed, same
## reasoning as spatial_goal.gd.

signal picked_up

## Where the glasses sit while carried, relative to the body (above its head).
@export var carry_offset: Vector2 = Vector2(0, -30)

@onready var found_condition: WinCondition = $FoundCondition
@onready var delivered_condition: WinCondition = $DeliveredCondition
@onready var visual: CanvasItem = $Visual

var _carried: bool = false
var _delivered: bool = false
var _body: CharacterBody2D
var _head: Node2D


func _ready() -> void:
	set_physics_process(false)
	body_entered.connect(_on_body_entered)
	_head = get_tree().get_first_node_in_group("head") as Node2D
	if _head == null:
		push_warning("Glasses: no head in the scene — they can never be delivered.")
	# Velma opens without them even if an F6 left Game.wearing_glasses true.
	Game.wearing_glasses = false
	if _head is Head:
		(_head as Head).refresh_face()


func _physics_process(_delta: float) -> void:
	if _body == null or _delivered:
		return
	global_position = _body.global_position + carry_offset


func _on_body_entered(body: Node2D) -> void:
	if _carried or not (body is CharacterBody2D):
		return
	_carried = true
	_body = body
	found_condition.satisfy()
	# Deferred: Godot forbids changing an Area2D's monitoring state from
	# inside its own body_entered/exited signal.
	set_deferred("monitoring", false)
	set_physics_process(true)
	picked_up.emit()


## Tween off the body toward `dest`. The day calls this after vision expands.
func fly_to(dest: Vector2, duration: float) -> void:
	set_physics_process(false)
	var tw: Tween = create_tween()
	tw.tween_property(self, "global_position", dest, duration)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tw.finished


func deliver() -> void:
	if _delivered:
		return
	_delivered = true
	set_physics_process(false)
	visual.visible = false
	if _head is Head:
		(_head as Head).set_wearing_glasses(true)
	delivered_condition.satisfy()
