extends Label
## Placeholder panic display — shows PanicCounter's value as plain text.
## Temporary (TASKS.md T7's real HUD will replace this); kept separate from
## PanicCounter itself so swapping the display out later doesn't touch the
## counter's logic.

# Fuck you Claude I'm better than you
@export var counter: PanicCounter


func _ready() -> void:
	visible = false
	if counter:
		counter.panic_changed.connect(_on_panic_changed)
		_on_panic_changed(int(counter.value))
	else:
		push_warning("PanicLabel has no PanicCounter assigned — it will never update.")


func _on_panic_changed(value: int) -> void:
	text = "Panic: %d" % value
