extends Area2D
## SpatialGoal — the day's destination marker. Logs a win when the body reaches it.

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		print("You won")
