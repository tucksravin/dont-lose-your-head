extends Node2D
## Lockdown's mind + body needs: a short chain of glance-math puzzles answered
## by standing on a floor pad and pressing `interact`, while thoughts fall.
## `start()` is the gate: Lockdown's setup beat calls it once the head is seated
## so the question and pads don't appear in the empty room.
##
## One WinCondition per DESIGN need — not one per puzzle. The chain is internal
## state; the last correct answer satisfies *both* keys (surviving the rain is
## the body need; finishing the chain is the mind need). A hit still fails
## through DayManager. A wrong pad speeds ThoughtRain — no panic on the head.

signal puzzle_advanced(index: int)

@onready var body_need: WinCondition = $BodyNeed
@onready var mind_need: WinCondition = $MindNeed
@onready var question: Label = $Question

## The pop a wrong plate gives the body: y is the upward kick (the body's own
## jump is −300, so this reads as a bit more than a jump), x the sideways
## stumble away from the plate.
@export var buck_velocity: Vector2 = Vector2(110.0, -380.0)

## prompt, three choices, index of the correct choice (0–2).
## Escalates; last one is a glance-impossible calc-3 flux (div thm → 12π/5).
var puzzles: Array = [
	["17 − 9", ["8", "7", "26"], 0],
	["6 × 7", ["36", "42", "48"], 1],
	["125 / 5", ["12", "25", "5"], 1],
	[
		"∯_S ⟨x³, y³, z³⟩ · dS   on  x²+y²+z²=1  (outward)",
		["12π/5", "4π/3", "4π"],
		0,
	],
]

var _index: int = 0
var _pads: Array[AnswerPad] = []
var _won: bool = false
var _started: bool = false


func _ready() -> void:
	body_need.key = "body"
	mind_need.key = "mind"
	question.visible = false
	# Pads add themselves to the group in their own _ready. This node may be
	# listed first in the scene, so wait until every sibling has entered.
	call_deferred("_bind_pads")


func start() -> void:
	if _started:
		return
	_started = true
	question.visible = true
	_show_current()


func _bind_pads() -> void:
	for node in get_tree().get_nodes_in_group("answer_pad"):
		var pad: AnswerPad = node as AnswerPad
		if pad == null:
			continue
		_pads.append(pad)
		pad.chosen.connect(_on_chosen)
	_pads.sort_custom(func(a: AnswerPad, b: AnswerPad) -> bool:
		return a.global_position.x < b.global_position.x)
	if _pads.size() != 3:
		push_warning("PuzzleChain: expected 3 answer pads, found %d." % _pads.size())


func _show_current() -> void:
	if _index >= puzzles.size():
		return
	var puzzle: Array = puzzles[_index]
	var prompt: String = str(puzzle[0])
	question.text = prompt
	question.add_theme_font_size_override("font_size", 14 if prompt.length() > 22 else 22)
	var choices: Array = puzzle[1]
	for i in mini(_pads.size(), choices.size()):
		_pads[i].set_choice(str(choices[i]))
	puzzle_advanced.emit(_index)


func _on_chosen(value: String) -> void:
	if not _started or _won or _index >= puzzles.size():
		return
	var puzzle: Array = puzzles[_index]
	var choices: Array = puzzle[1]
	var correct_index: int = int(puzzle[2])
	var correct: String = str(choices[correct_index])
	if value != correct:
		_on_wrong()
		return
	_index += 1
	if _index >= puzzles.size():
		_win()
		return
	_show_current()


## Wrong answer: the plate you landed on bucks you off it — a small pop, you
## keep control, the day carries on (Tucker, Sat: "just make it a little
## launch") — and the rain speeds up, which is the real punishment.
func _on_wrong() -> void:
	_buck_body()
	var rain: Node = get_tree().get_first_node_in_group("thought_rain")
	if rain != null and rain.has_method("speed_up"):
		rain.call("speed_up")
		return
	push_warning("PuzzleChain: wrong answer but no ThoughtRain — rain will not speed up.")


## Pop the body off the plate. Just velocity — body.gd keeps driving it, so the
## player never loses control and gravity brings them down normally. The
## sideways nudge is overwritten the moment they hold a direction again, which
## is deliberate: it is a stumble, not a knockback you have to fight.
func _buck_body() -> void:
	var body: CharacterBody2D = get_tree().get_first_node_in_group("body") as CharacterBody2D
	if body == null:
		return
	body.velocity.y = buck_velocity.y
	var away: float = signf(body.global_position.x - global_position.x)
	if is_zero_approx(away):
		away = 1.0
	body.velocity.x = away * buck_velocity.x


func _win() -> void:
	_won = true
	mind_need.satisfy()
	body_need.satisfy()
