extends Node2D
## Spawns FallingThoughts across the top of the screen until the day ends.
##
## Stops on win or fail so a thought can't fail you during the head's exit
## (DayManager already no-ops fail() once _ending, but we shouldn't keep
## spawning either). Timer is a child node created here so the day scene
## doesn't need to wire one.

@export var thought_scene: PackedScene
@export var interval: float = 1.1
@export var start_delay: float = 1.0
@export var fall_speed: float = 140.0
## Each wrong pad multiplies spawn rate and fall speed by this (3 = 3×).
@export var miss_mult: float = 3.0
## Floor / cap so a few misses can't zero the timer or teleport drops.
@export var min_interval: float = 0.06
@export var max_fall_speed: float = 900.0
@export var min_x: float = 24.0
@export var max_x: float = 616.0
## Lockdown leaves this off until the head is on the pedestal.
@export var autostart: bool = true
## How many thoughts drop at once. 1 is a single column; 2+ is a volley.
@export var burst: int = 1

var _timer: Timer
var _stopped: bool = false
var _begun: bool = false
var _misses: int = 0


func _ready() -> void:
	add_to_group("thought_rain")
	Events.day_completed.connect(_stop)
	Events.day_failed.connect(_on_failed)
	_timer = Timer.new()
	_timer.wait_time = interval
	_timer.timeout.connect(_spawn)
	add_child(_timer)
	if autostart:
		begin()


func begin() -> void:
	if _begun or _stopped:
		return
	_begun = true
	_tune()
	if start_delay <= 0.0:
		_timer.start()
		_spawn()
	else:
		get_tree().create_timer(start_delay).timeout.connect(_on_start)


func _on_start() -> void:
	if _stopped or not is_inside_tree():
		return
	_spawn()
	_timer.start()


func _spawn() -> void:
	if _stopped or thought_scene == null:
		return
	_tune()
	for _i in burst:
		_spawn_one(_current_fall_speed())


func _spawn_one(speed: float) -> void:
	if _stopped or thought_scene == null:
		return
	var thought: Node2D = thought_scene.instantiate() as Node2D
	if thought == null:
		return
	thought.position = Vector2(randf_range(min_x, max_x), -12.0)
	if "fall_speed" in thought:
		thought.set("fall_speed", speed)
	add_child(thought)


## A wrong pad. Found by group so PuzzleChain needs no scene path.
func speed_up() -> void:
	_misses += 1
	_tune()
	# Restart so the new interval applies now, not after the old wait finishes.
	if _begun and not _stopped and _timer != null and not _timer.is_stopped():
		_timer.start()


func _scale() -> float:
	return pow(miss_mult, float(_misses))


func _current_interval() -> float:
	return maxf(interval / _scale(), min_interval)


func _current_fall_speed() -> float:
	return minf(fall_speed * _scale(), max_fall_speed)


func _tune() -> void:
	if _timer == null:
		return
	_timer.wait_time = _current_interval()


func _on_failed(_reason: String) -> void:
	_stop()


func _stop() -> void:
	_stopped = true
	if _timer != null:
		_timer.stop()
	for child in get_children():
		if child == _timer:
			continue
		child.queue_free()
