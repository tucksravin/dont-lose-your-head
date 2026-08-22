extends CanvasLayer
## Reusable game-over overlay. Instance it in a day scene and call show_over()
## on a lose condition; Retry reloads the current scene.
##
## CanvasLayer (not a Control) so it always draws on top regardless of the
## day's z-ordering — same pattern as reunion's fade overlay. The whole layer
## runs with process_mode = Always (set in the .tscn) so the Retry button still
## responds while the rest of the tree is paused.

@onready var retry_button: Button = $Center/VBox/Retry


func _ready() -> void:
	visible = false
	retry_button.pressed.connect(_on_retry)


## Freeze the scene and show the overlay. Idempotent.
func show_over() -> void:
	if visible:
		return
	visible = true
	get_tree().paused = true


func _on_retry() -> void:
	Sfx.play(&"ui_confirm")
	# Unpause before reloading, or the fresh scene starts frozen.
	get_tree().paused = false
	get_tree().reload_current_scene()
