extends Control
## Boot scene. Exists only to prove the project runs and the input map works.
## Point `run/main_scene` in project.godot at the real entry scene when it exists.

const ACTIONS := ["move_left", "move_right", "jump", "interact", "restart", "pause"]

@onready var label: Label = $Label


func _unhandled_input(event: InputEvent) -> void:
	for action in ACTIONS:
		if event.is_action_pressed(action):
			label.text = "Don't Lose Your Head\n\ntemplate OK — input: %s" % action
