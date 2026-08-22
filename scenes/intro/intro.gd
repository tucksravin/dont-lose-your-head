extends Node2D
## Intro scene — scripted head chase.
##
## The head blob (HeadBlob, CharacterBody2D) moves right on a scripted path.
## The player controls the body via the instanced body.tscn scene, which runs
## its own _physics_process. When the head exits the viewport, both are
## auto-scrolled off screen (body.gd is disabled) and the next scene loads.
##
## NOTE: Camera2D is static (fixed at viewport centre) rather than parented to
## HeadBlob. This lets the head visibly run off the right edge — the whole
## visual point of the intro shot. Game-day scenes follow the head instead.
##
## TODO(cutscene): Before Phase.CHASE, add a short Tween separation animation:
##   skeleton stands still → intrusive thoughts appear →
##   head "pops" off (scale bounce + rightward Tween) → CHASE begins.
##   Docs: https://docs.godotengine.org/en/stable/classes/class_tween.html

enum Phase { CHASE, EXIT }

## How fast the head blob moves right (px/s).
@export var head_speed: float = 150.0
## Downward gravity for the head blob (px/s²). Body gravity is in body.gd.
@export var gravity: float = 980.0
## Pixels past the right viewport edge before EXIT triggers.
@export var exit_margin: float = 120.0
## Seconds to wait after EXIT starts before changing scene.
@export var exit_delay: float = 1.2
## Scene to load after the intro. body.tscn drives the player in CHASE;
## once wired, swap to the real day 1 path.
@export var next_scene: String = "res://scenes/days/day_template.tscn"

@onready var head_blob: CharacterBody2D = $HeadBlob
## Instanced body.tscn — body.gd drives player input in CHASE phase.
@onready var body_blob: CharacterBody2D = $Body

var phase: Phase = Phase.CHASE
var _exiting: bool = false


func _physics_process(delta: float) -> void:
	match phase:
		Phase.CHASE:
			_move_head(delta)
			# body.gd handles player input automatically in CHASE.
			_check_exit()
		Phase.EXIT:
			_scroll_blob(head_blob, delta)
			_scroll_blob(body_blob, delta)


## Scripted rightward movement for the head blob.
func _move_head(delta: float) -> void:
	head_blob.velocity.x = head_speed
	if head_blob.is_on_floor():
		head_blob.velocity.y = 0.0
	else:
		head_blob.velocity.y += gravity * delta
	head_blob.move_and_slide()


## Check whether the head has exited the right side of the viewport.
## get_viewport_rect() returns screen pixels (0,0)→(640,360) regardless of
## camera. With a static camera at (320,180) this maps 1-to-1 to world coords.
func _check_exit() -> void:
	if _exiting:
		return
	var right_edge: float = get_viewport_rect().size.x
	if head_blob.global_position.x > right_edge + exit_margin:
		_exiting = true
		# Disable body.gd so we can drive the body manually in EXIT phase.
		# PROCESS_MODE_DISABLED stops _physics_process without removing the node.
		body_blob.process_mode = Node.PROCESS_MODE_DISABLED
		phase = Phase.EXIT
		get_tree().create_timer(exit_delay).timeout.connect(_on_exit_delay)


## Move a CharacterBody2D rightward at head_speed with gravity; used in EXIT.
func _scroll_blob(blob: CharacterBody2D, delta: float) -> void:
	blob.velocity.x = head_speed
	if blob.is_on_floor():
		blob.velocity.y = 0.0
	else:
		blob.velocity.y += gravity * delta
	blob.move_and_slide()


func _on_exit_delay() -> void:
	Game.change_scene(next_scene)
