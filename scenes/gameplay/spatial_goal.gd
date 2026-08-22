extends Area2D
## SpatialGoal — the day's destination marker.
## When the body reaches it, load next_scene via the Game autoload.
## Set next_scene in the Inspector (or as a property override in the day's .tscn).

@export var next_scene: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not next_scene.is_empty():
		Game.change_scene(next_scene)
