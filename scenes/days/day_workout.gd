extends Node2D
## Working Out (C3c): walk to the barbell, interact, mash `jump` to shove
## kikis off the loose head. The swarm's circle blocks the walk to the head.
## Creep starts after pickup. Fail = sunset or kikis touching the head.
## Both WinConditions live on the swarm and fire when pressure hits 0.
##
## Body is `is_scripted` while lifting so the jump key is mash, not hop
## (body.gd ignores input in that mode). DayManager still owns fail / release.

enum Phase { FIND_BAR, LIFT, DONE }

@export var find_text: String = "Walk to the barbell and press E."
@export var lift_text: String = "Mash W or ↑ — push the thoughts off your head."

@onready var body: CharacterBody2D = $Body
@onready var instruction: Label = $Instruction
@onready var barbell: Area2D = $Barbell
@onready var swarm: Node2D = $KikiSwarm


var _phase: Phase = Phase.FIND_BAR


func _ready() -> void:
	instruction.text = find_text
	if barbell.has_signal("picked_up"):
		barbell.connect("picked_up", _on_barbell_picked_up)
	Events.day_completed.connect(_on_day_completed)
	Events.day_failed.connect(_on_day_failed)


func _process(_delta: float) -> void:
	if _phase != Phase.LIFT:
		return
	if Input.is_action_just_pressed("jump"):
		if swarm.has_method("push"):
			swarm.call("push")
		if barbell.has_method("pump"):
			barbell.call("pump")


func _on_barbell_picked_up() -> void:
	if _phase != Phase.FIND_BAR:
		return
	_phase = Phase.LIFT
	body.velocity = Vector2.ZERO
	body.is_scripted = true
	instruction.text = lift_text
	if swarm.has_method("begin"):
		swarm.call("begin")


func _on_day_completed() -> void:
	_phase = Phase.DONE


func _on_day_failed(_reason: String) -> void:
	_phase = Phase.DONE
