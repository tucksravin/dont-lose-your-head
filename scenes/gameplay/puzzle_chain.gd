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
var puzzles: Array = [
	["2 + 2", ["3", "4", "5"], 1],
	["1 + 1", ["2", "3", "1"], 0],
	["5 - 2", ["4", "2", "3"], 2],
	["3 + 3", ["5", "6", "9"], 1],
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
	question.text = str(puzzle[0])
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
