extends Area2D
## SpatialGoal — a place the body has to reach to meet one of the day's needs.
##
## Satisfies its child WinCondition when the body touches it. It no longer loads
## a scene itself: the day is won when *every* condition is met, which is
## WinConditions' call, not this node's.
##
## Area2D rather than a body because we only want overlap detection — nothing
## should collide with a goal marker or be pushed by it.

## Which need reaching this goal meets. Set it per instance in the day scene;
## it's forwarded to the child WinCondition so day authors only set it in one
## place instead of drilling into the instanced sub-scene.
@export_enum("body", "mind") var key: String = "body"

@onready var condition: WinCondition = $WinCondition


func _ready() -> void:
	condition.key = key
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# The body is the only CharacterBody2D in a day; the head is a RigidBody2D.
	if body is CharacterBody2D:
		condition.satisfy()
