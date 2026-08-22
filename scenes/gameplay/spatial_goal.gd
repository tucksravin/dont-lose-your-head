extends Area2D
## SpatialGoal — a place the body reaches to meet one of the day's needs.
##
## A dumb sensor: on body overlap it calls satisfy() on its child WinCondition,
## which signals UP to the WinConditionManager. It no longer changes scenes or
## knows anything about the head — that logic moved to the DayManager.
##
## Area2D because we only want overlap detection; the goal shouldn't collide
## with or push anything.

## Which need reaching this goal meets. Set per instance in the day scene; it's
## forwarded to the child WinCondition so authors set it in one place.
@export_enum("body", "mind") var key: String = "body"

@onready var condition: WinCondition = $WinCondition


func _ready() -> void:
	condition.key = key
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# The body is the only CharacterBody2D in a day; the head is a RigidBody2D.
	if body is CharacterBody2D:
		condition.satisfy()
