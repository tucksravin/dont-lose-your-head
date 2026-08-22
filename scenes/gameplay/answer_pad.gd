class_name AnswerPad
extends Area2D
## A floor answer plate. **You choose it by LANDING on it** — no key press
## (Tucker, Sat: "remove all uses of the E key, when we hit a trigger it just
## happens"). Area2D so it never pushes the body around.
##
## Why landing and not merely touching: the plates sit on the floor the body
## walks along, and a wrong answer fails the day — with touch-to-choose, the
## walk from the pedestal to the plate you want crosses the ones you don't
## (the body starts to the RIGHT of all three), so the day would be lost
## before the player had done anything. Landing is a deliberate act: walking
## across a plate is always safe, a hop onto one commits. That is what makes
## the plates small enough to jump over (32x8) worth doing — you hop the
## answers you don't want and land on the one you do.
##
## The test is geometric on purpose. The body's `landed` signal (body.gd, the
## air->floor edge) fires inside the body's own _physics_process, but an
## Area2D's `body_entered` is delivered at the END of the physics step — so on
## a hop onto a plate the landing arrives BEFORE this node knows the body is
## overlapping, and an occupancy-gated check misses it every time (measured:
## 0 of 4 hops registered). So we ask where the body is instead of whether the
## overlap has been processed: it landed on us if its centre is within
## `land_tolerance` of ours. The Area2D still does the highlight.
##
## Docs: https://docs.godotengine.org/en/stable/classes/class_area2d.html

signal chosen(value: String)

@export var value: String = ""
## How far the body's centre may be from the plate's centre and still count as
## landing on it (px). 16 = the plate's own half-width, so the body has to come
## down over the plate, not merely clip its edge.
@export var land_tolerance: float = 16.0
## Ignore a landing this far above the plate (px) — a landing on something
## else (a platform overhead) is not an answer.
@export var land_height: float = 24.0

@onready var label: Label = $Label
## The plate itself — button.png (Tucker's), same art as the panic day's floor
## button: `off` with its studs up, `press` when the body is on it, holding on
## `on`. The pressed plate IS the feedback, so there is no colour swap.
@onready var visual: AnimatedSprite2D = $Visual

var _bodies: int = 0
var _enabled: bool = true
## The body we are listening to, while the pad is live.
var _body: Node2D = null


func _ready() -> void:
	add_to_group("answer_pad")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_label()
	_set_occupied(false)


func set_choice(next_value: String) -> void:
	value = next_value
	_refresh_label()


## Hide and ignore the plate (setup beat) or show it and accept landings
## (puzzle). Toggling `monitoring` deferred so we don't change physics mid-query;
## then recount overlaps because enabling does not re-fire `body_entered` for a
## body that is already standing here.
func set_enabled(on: bool) -> void:
	_enabled = on
	visible = on
	set_deferred("monitoring", on)
	if on:
		_listen()
		call_deferred("_sync_occupation")
	else:
		_unlisten()
		_bodies = 0
		_set_occupied(false)


func _refresh_label() -> void:
	if label != null:
		label.text = value


## Start/stop listening to the body's landings. The body adds itself to the
## "body" group in its _ready (body.gd), so no node path is needed.
func _listen() -> void:
	_unlisten()
	var body: Node2D = get_tree().get_first_node_in_group("body") as Node2D
	if body != null and body.has_signal("landed"):
		_body = body
		body.connect("landed", _on_body_landed)


func _unlisten() -> void:
	if _body != null and is_instance_valid(_body) \
			and _body.is_connected("landed", _on_body_landed):
		_body.disconnect("landed", _on_body_landed)
	_body = null


## The body touched down. If it came down on this plate, that is the answer.
func _on_body_landed() -> void:
	if not _enabled or _body == null or not is_instance_valid(_body):
		return
	var offset: Vector2 = _body.global_position - global_position
	if absf(offset.x) <= land_tolerance and absf(offset.y) <= land_height:
		chosen.emit(value)


func _sync_occupation() -> void:
	if not monitoring:
		return
	_bodies = 0
	for body in get_overlapping_bodies():
		if body is CharacterBody2D:
			_bodies += 1
	# No `chosen` here on purpose: this runs when the plates switch ON under a
	# body that is already standing there, which is not a landing.
	_set_occupied(_bodies > 0)


func _on_body_entered(body: Node2D) -> void:
	if not _enabled or not body is CharacterBody2D:
		return
	_bodies += 1
	if _bodies == 1:
		_set_occupied(true)


func _on_body_exited(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	_bodies = maxi(_bodies - 1, 0)
	if _bodies == 0:
		_set_occupied(false)


## Just the look — the choice is made in _on_body_landed(). `press` is a
## one-shot that ends on the held-down frame, so standing on the plate keeps it
## down and stepping off pops it back up.
func _set_occupied(occupied: bool) -> void:
	if visual == null or visual.sprite_frames == null:
		return
	var anim: StringName = &"press" if occupied else &"off"
	if visual.sprite_frames.has_animation(anim) and visual.animation != anim:
		visual.play(anim)
