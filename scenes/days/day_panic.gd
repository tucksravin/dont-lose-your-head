extends Node2D
## Panic day (rework, thoughts.md): the head hangs in a cage in the air.
## Moving winds panic up (PanicCounter fails the day at max). Kikis fly
## out of the cage — jump them; a hit is `DayManager.fail("kiki")`. Stand
## on the floor button and press `interact` to open the cage.
##
## Body need + mind need both live on the button: one action, two needs,
## same as Velma's glasses. PanicCounter is fail-only now.
##
## FlyingKiki is reused from the mirror day. They spawn just left of the
## button and fly left. Standing on the button puts the body in `kiki_safe`
## so a hit there is ignored. Timer spawn is the same idiom as ThoughtRain.

@export var kiki_scene: PackedScene
@export var kiki_interval: float = 1.2
@export var kiki_start_delay: float = 0.6
@export var kiki_speed: float = 180.0
## Spawn just left of the floor button, at jump height (button origin is feet).
@export var kiki_spawn_offset: Vector2 = Vector2(-40.0, -16.0)
@export var drop_time: float = 0.35
@export var floor_y: float = 306.0
@export var instruction_text: String = "E at the button frees the cage. Moving winds panic. Jump the thoughts."

@onready var body: CharacterBody2D = $Body
@onready var head: Head = $Head
@onready var release: Area2D = $ReleaseButton
@onready var body_need: WinCondition = $BodyNeed
@onready var mind_need: WinCondition = $MindNeed
@onready var instruction: Label = $Instruction
@onready var chain: ColorRect = $Chain

var _done: bool = false
var _opened: bool = false
var _on_button: bool = false
var _kiki_timer: Timer


func _ready() -> void:
	instruction.text = instruction_text
	if kiki_scene == null:
		kiki_scene = load("res://scenes/gameplay/flying_kiki.tscn") as PackedScene
	_kiki_timer = Timer.new()
	_kiki_timer.wait_time = kiki_interval
	_kiki_timer.timeout.connect(_spawn_kiki)
	add_child(_kiki_timer)
	if kiki_start_delay <= 0.0:
		_kiki_timer.start()
		_spawn_kiki()
	else:
		get_tree().create_timer(kiki_start_delay).timeout.connect(_on_kiki_start)
	release.body_entered.connect(_on_button_entered)
	release.body_exited.connect(_on_button_exited)
	Events.day_completed.connect(_stop)
	Events.day_failed.connect(_stop_failed)


func _on_kiki_start() -> void:
	if _done or not is_inside_tree():
		return
	_spawn_kiki()
	_kiki_timer.start()


func _process(_delta: float) -> void:
	if _done:
		return
	if _on_button and Input.is_action_just_pressed("interact"):
		_open_cage()


func _on_button_entered(other: Node2D) -> void:
	if other is CharacterBody2D:
		_on_button = true
		other.add_to_group("kiki_safe")
		var prompt: Label = release.get_node_or_null("Prompt") as Label
		if prompt != null:
			prompt.visible = true


func _on_button_exited(other: Node2D) -> void:
	if other is CharacterBody2D:
		_on_button = false
		other.remove_from_group("kiki_safe")
		var prompt: Label = release.get_node_or_null("Prompt") as Label
		if prompt != null:
			prompt.visible = false


func _open_cage() -> void:
	if _opened:
		return
	_opened = true
	_stop()
	mind_need.satisfy()
	body_need.satisfy()


func _spawn_kiki() -> void:
	if _done or kiki_scene == null:
		return
	var kiki: Node2D = kiki_scene.instantiate() as Node2D
	if kiki == null:
		return
	kiki.global_position = release.global_position + kiki_spawn_offset
	# Always left — they come from beside the button toward the approach.
	kiki.set("direction", Vector2.LEFT)
	kiki.set("speed", kiki_speed)
	add_child(kiki)


## DayManager awaits this before `head.release()`. Drop the hanging skull
## onto the floor so the roll-off starts from the ground. F3 / day_chain
## satisfy() without `_opened`, so we no-op (same guard as the mirror throw).
func _before_head_release() -> void:
	if not _opened:
		return
	head.caged = false
	if head.has_method("refresh_face"):
		head.refresh_face()
	if chain != null:
		chain.visible = false
	var land: Vector2 = Vector2(head.global_position.x, floor_y)
	var drop: Tween = create_tween()
	drop.tween_property(head, "global_position", land, drop_time)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await drop.finished


func _stop() -> void:
	_done = true
	if _kiki_timer != null:
		_kiki_timer.stop()
	for child in get_tree().get_nodes_in_group("flying_kiki"):
		child.queue_free()


func _stop_failed(_reason: String) -> void:
	_stop()
