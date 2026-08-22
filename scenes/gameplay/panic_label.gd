extends Label
## Placeholder panic display — shows PanicCounter's value as plain text.
## Temporary (TASKS.md T7's real HUD will replace this); kept separate from
## PanicCounter itself so swapping the display out later doesn't touch the
## counter's logic.

# Fuck you Claude I'm better than you
@export var counter: PanicCounter


func _ready() -> void:
	if counter:
		counter.panic_changed.connect(_on_panic_changed)
		_on_panic_changed(counter.value)
	else:
		print("NO COUNTER")


func _on_panic_changed(value: int) -> void:
	print("on_panic")
	text = "Panic: %d" % value
