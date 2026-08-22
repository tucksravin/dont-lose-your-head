extends Area2D
class_name Glasses
## Velma day: a pickup on the ground that has to be carried to the head.
##
## Both of the day's needs live on this one node because they're really one
## action in two steps, not two independent goals (docs/days/velma-plan.md
## §4.2): touching it on the ground satisfies the body need ("find them"),
## then carrying it within reach of the head satisfies the mind need
## ("hand them over"). Area2D rather than a body: only overlap detection is
## needed, same reasoning as spatial_goal.gd.
##
## Pickup art is glasses.png (16×16, bottom-aligned in the cell).

## How close the head has to be, once carried, before they count as handed over.
@export var delivery_radius: float = 50.0
## Where the glasses sit while carried, relative to the body (above its head).
@export var carry_offset: Vector2 = Vector2(0, -30)

@onready var found_condition: WinCondition = $FoundCondition
@onready var delivered_condition: WinCondition = $DeliveredCondition
@onready var visual: CanvasItem = $Visual

var _carried: bool = false
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
	if _body == null:
		return
	global_position = _body.global_position + carry_offset
	if _head != null and global_position.distance_to(_head.global_position) <= delivery_radius:
		_deliver()


func _on_body_entered(body: Node2D) -> void:
	if _carried or not (body is CharacterBody2D):
		return
	_carried = true
	_body = body
	found_condition.satisfy()
	# No longer a ground pickup — stop scanning for overlaps, start following.
	# Deferred: Godot forbids changing an Area2D's monitoring state from
	# inside its own body_entered/exited signal (the call that got us here).
	set_deferred("monitoring", false)
	set_physics_process(true)


func _deliver() -> void:
	set_physics_process(false)
	delivered_condition.satisfy()
	visual.visible = false
	if _head is Head:
		(_head as Head).set_wearing_glasses(true)
