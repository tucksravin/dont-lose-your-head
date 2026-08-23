extends Node2D
## Velma: climb from the right to the centre glasses, then throw them at
## the perched head. Body and head each have a small clear circle from
## the start. The room unblurs only when the glasses hit the skull.
##
## Lives on the day root (same as lockdown) because the throw/knock is a
## beat *between* the two needs, not a WinCondition. `play_throw()` is the
## authored 3-frame sheet on the body.

## Hold after pickup so the perched head (already in its own clear
## circle) is readable, then throw. Pickup does not lift the blur.
@export var see_pause: float = 0.7
@export var throw_time: float = 0.4
@export var knock_time: float = 0.45
@export var puzzle_text: String = "Climb for the glasses. Throw them at your head."

@onready var body: CharacterBody2D = $Body
@onready var head: Head = $Head
@onready var glasses: Glasses = $Glasses
@onready var vision: VisionBlur = $VisionBlur
@onready var instruction: Label = $Instruction


func _ready() -> void:
	instruction.text = puzzle_text
	glasses.picked_up.connect(_on_glasses_picked)


func _on_glasses_picked() -> void:
	_throw_at_head()


func _throw_at_head() -> void:
	# is_scripted (not process_mode DISABLED): input is ignored but the
	# CharacterBody2D stays in the physics space. Zero velocity so a held
	# run key can't carry them off the glasses platform mid-throw.
	body.velocity = Vector2.ZERO
	body.is_scripted = true
	var sprite: AnimatedSprite2D = body.get_node_or_null("Visual") as AnimatedSprite2D
	if sprite != null:
		sprite.flip_h = head.global_position.x < body.global_position.x
	if see_pause > 0.0:
		await get_tree().create_timer(see_pause).timeout
	if body.has_method("play_throw"):
		body.call("play_throw")
	await glasses.fly_to(head.global_position, throw_time)
	glasses.deliver()


## DayManager awaits this after both needs, before head.release().
## The glasses just hit — drop the skull off the perch onto the floor
## so the scripted roll starts on the ground, not in the air.
func _before_head_release() -> void:
	head.set_solid(false)
	var dest: Vector2 = Vector2(head.global_position.x + 24.0, 306.0)
	var tw: Tween = create_tween()
	tw.tween_property(head, "global_position", dest, knock_time)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tw.finished
