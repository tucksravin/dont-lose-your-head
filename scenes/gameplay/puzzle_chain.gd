extends Node2D
## Lockdown's mind + body needs: a short chain of glance-math puzzles answered
## by standing on a floor pad and pressing `interact`, while thoughts fall.
## `start()` is the gate: Lockdown's setup beat calls it once the head is seated
## so the question and pads don't appear in the empty room.
##
## One WinCondition per DESIGN need — not one per puzzle. The chain is internal
## state; the last correct answer satisfies *both* keys (surviving the rain is
## the body need; finishing the chain is the mind need). A wrong pad or a hit
## elsewhere fails through DayManager.

signal puzzle_advanced(index: int)

@onready var body_need: WinCondition = $BodyNeed
@onready var mind_need: WinCondition = $MindNeed
@onready var question: Label = $Question

## prompt, three choices, index of the correct choice (0–2).
## Escalates; last one is a glance-impossible calc-3 flux (div thm → 12π/5).
var puzzles: Array = [
	["17 − 9", ["8", "7", "26"], 0],
	["6 × 7", ["36", "42", "48"], 1],
	["d/dx [x²]  at x = 5", ["25", "10", "5"], 1],
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
		_fail("wrong")
		return
	_index += 1
	if _index >= puzzles.size():
		_win()
		return
	_show_current()


func _win() -> void:
	_won = true
	mind_need.satisfy()
	body_need.satisfy()


func _fail(reason: String) -> void:
	var manager: Node = get_tree().get_first_node_in_group("day_manager")
	if manager != null and manager.has_method("fail"):
		manager.call("fail", reason)
