# Velma day — implementation plan

**Source idea:** [brainstorm.md — "Velma"](brainstorm.md#velma): *"I can't see without my glasses! The head can't see and the screen's all blurry, big glasses. Head has glasses, they fall off in the intro scene, this is the first challenge, getting the glasses back to the head."* Also referenced in the Day Plan sketch there: `Intro -> Velma -> Don't Panic -> Working Out -> Reunion`.

**Status:** proposal — the brainstorm line is one sentence, not a day card. Per [DESIGN.md §3.7](../DESIGN.md#37-day-card--ideas-are-collecting-in-daysbrainstormmd) a day needs `name · snag/mind need · body need · verb for each · twist · length` before it's buildable. §1 below turns the sentence into that card by reusing the existing chassis ([HOWTO.md](HOWTO.md), [CODEBASE.md §5](../CODEBASE.md)) — it does **not** invent new architecture. Per [CLAUDE.md §2](../../CLAUDE.md), the choices below are a recommendation with the alternatives listed, not a lock — say so at standup or in Discord before someone starts building, and copy the picked card into DESIGN.md §2.1 next to the Bridge (C2) row.

**Scope estimate:** ~2–2.5 h (one new reusable node + one new day file) — right at the CLAUDE.md §7 "flag before starting" line. Flagging it here so whoever picks this up knows it's a full session, not a 45-minute task.

**Built 2026-08-22** (`scenes/gameplay/glasses.gd/.tscn`, `scenes/gameplay/vision_blur.gd/.tscn`, `scenes/days/day_velma.tscn`; `tools/smoke_test.sh` ALL GREEN — journal: `journals/smahr.md`). Two calls below were resolved differently than §2's original sketch, on later direction:
- **§4.2 (carry mechanic vs. two goals)** — resolved as the real carry mechanic, not the two-independent-`SpatialGoal`s default. `Glasses` (`scenes/gameplay/glasses.gd`) is one `Area2D` with two `WinCondition` children: touching it on the ground satisfies **body** and starts it following the body (`carry_offset`); getting within `delivery_radius` of the head satisfies **mind** and hides it. The code block in §2.1 below is the superseded two-goals sketch — `glasses.gd` is the real thing now.
- **The vignette centring** — `VisionBlur` now tracks the body's position every frame (screen UV = world position ÷ 640×360, since the camera is fixed — same assumption as `head.gd`'s `_is_off_screen()`), not the fixed screen-centre in the §2.1 sketch below.
- One real bug found building this and worth knowing for any future "pick up" node: `Area2D.monitoring` can't be set synchronously from inside its own `body_entered` handler — Godot throws `Function blocked during in/out signal`. Use `set_deferred("monitoring", false)`.
- **§4.3's "real screen-space blur… a stretch swap for later"** — done, sooner than expected. `vision_blur.gdshader` is a `canvas_item` screen-reading shader (this project's first shader) that reads `SCREEN_TEXTURE` at a high mip level for a genuine blur, no hand-rolled kernel. Its first version converted the body's position to screen pixels via `get_viewport().get_canvas_transform()` on the CPU side — that turned out to be the wrong approach (fixed 2026-08-22 12:03): the mask is now computed from the `Fog` rect's own local `VERTEX` in the shader's `vertex()` stage instead, which Godot already keeps in the same logical 640×360 space as everything else, no manual transform needed.
- **Glasses moved onto a climb** (2026-08-22 12:03, on direction) — no longer on flat ground. `Platform1`–`Platform4` in `day_velma.tscn` copy `platforming_day.tscn`'s exact stair (76×16, `one_way_collision`, 60 px right / 36 px up per step); `Glasses` sits atop `Platform4` at (320,176). The §2.2 layout description below (glasses at (300,320) on flat ground) is superseded — the scene file is current.

The code in §2 below is kept as the original design record; treat the files on disk as current. **Still not visually verified** — reload the scene / restart Godot before judging it (an editor session has had this project open through multiple rounds of on-disk changes now).

---

## 1. The day card

| | |
|---|---|
| **Name** | Velma (placeholder — same status as "Lockdown" in the brainstorm) |
| **Snag (mind need = what befalls the head)** | The head's glasses came off (in the intro, or at the top of this scene — open call, §4.1) and it can't see. Represented on screen as a **vignette over the whole play area** — the player is half-blind too, not just the head (DESIGN thesis: *the mind and body share what happens to either one*). |
| **Body need** | Walk to where the glasses landed (a `SpatialGoal`, `key = "body"`) — the "search" beat, harder because of the vignette. |
| **Mind need** | Carry them back to the head (a second `SpatialGoal`, `key = "mind"`, positioned by the head) — the "return" beat; the vignette lifts the moment this is met, so the payoff is seeing the whole room clearly again, right before the head rolls off. |
| **Verb for each** | *search* (body) → *return* (mind) |
| **Twist (recommended, cheap — §2.2)** | The vignette closes in faster the faster the body moves — sprinting blind makes things worse, walking carefully keeps more of the screen visible. Optional; cut it first if short on time (§4.3). |
| **Length** | ~30 s, per the chassis default (`Sun.day_length`) |

Reasoning for splitting "get the glasses back to the head" into two `SpatialGoal`s rather than a literal pick-up-and-carry item: the chassis has no "carry an object" verb yet (nothing in `scenes/gameplay/` or `scenes/body/` picks up or holds anything — confirmed by reading `spatial_goal.gd`, `body.gd`), and building one is a bigger, reusable chassis feature, not a one-day job. §4.2 below spells this out as an open call with the real alternative.

---

## 2. New pieces and where they live

Two additions, following the existing "needs are chassis atoms, days are thin scenes" split (CODEBASE.md §5):

### 2.1 `scenes/gameplay/vision_blur.tscn` + `.gd` — reusable "can't see" overlay

A new atom alongside `panic_counter.gd` and `sky_drift.gd` — any future day that wants a vision-impaired beat reuses this, not just Velma.

**What it is, in Godot terms:** a `CanvasLayer` (so it draws in screen space, above the world, below the `Instruction` HUD label) holding one `TextureRect` whose texture is a [`GradientTexture2D`](https://docs.godotengine.org/en/stable/classes/class_gradienttexture2d.html) — a **built-in Godot resource that renders a gradient procedurally**, so this needs no external image (keeps the "no generative art" rule moot — there's no art asset at all, just a math gradient) and no shader (a real blur shader is a new Godot concept for this team and more time than the effect needs — see the "twist" alternative in §4.3 of TASKS.md's spirit: first-timer sinks to timebox). It's built once in `_ready()`, radial, dark at the palette's outline colour (`#201c02`, transparent alpha) at the edges, fully clear at the centre.

**How it knows the day was won partway through:** it listens on the `Events` bus the same way `Sfx` already does (CODEBASE.md §3) — `Events.condition_satisfied(key)` is emitted by `WinConditionManager._on_satisfied()` (verified in `scenes/gameplay/win_condition_manager.gd:57`, not the dead `Events.sunset`), so `VisionBlur` needs no `NodePath` to anything in the day scene. This is the same reason `PanicCounter` finds the day manager by group instead of a path: one owner per `.tscn`, minimal wiring.

```gdscript
extends CanvasLayer
class_name VisionBlur
## A translucent radial vignette over the whole screen — the head can't see,
## so (per the game's thesis) neither can the body. Lifts once a chosen
## WinCondition key is met.
##
## Placeholder-speed effect (a GradientTexture2D, not a shader): correct for
## a jam. A real screen-space blur is a stretch swap for later — see
## docs/days/velma-plan.md §4.3.
##
## Docs: https://docs.godotengine.org/en/stable/classes/class_gradienttexture2d.html

## Which need lifts the fog when satisfied.
@export_enum("body", "mind") var lift_on_key: String = "mind"
## Vignette opacity at the very edge of the screen (0 = invisible, 1 = opaque).
@export_range(0.0, 1.0) var edge_darkness: float = 0.85
## Radius (px) of the fully-clear centre before the gradient starts darkening.
@export var clear_radius: float = 90.0
## Seconds for the fog to fade out once the day lifts it.
@export var fade_duration: float = 0.6
## Optional twist (§4.3 — cut this @export and the two lines that use it if
## the twist is dropped): darkens further, up to this many extra px of clear
## radius lost, scaled by how fast the body is moving.
@export var speed_penalty_radius: float = 30.0
@export var speed_penalty_at_speed: float = 150.0  ## body.gd's default `speed`

@onready var _rect: TextureRect = $Fog
@onready var _gradient: Gradient = Gradient.new()
@onready var _texture: GradientTexture2D = GradientTexture2D.new()

var _body: CharacterBody2D
var _lifted: bool = false


func _ready() -> void:
	_gradient.set_color(0, Color("201c02", 0.0))
	_gradient.set_color(1, Color("201c02", edge_darkness))
	_texture.gradient = _gradient
	_texture.fill = GradientTexture2D.FILL_RADIAL
	_texture.fill_from = Vector2(0.5, 0.5)
	_texture.width = 640
	_texture.height = 360
	_rect.texture = _texture
	_apply_radius(clear_radius)
	_body = get_tree().get_first_node_in_group("body") as CharacterBody2D
	Events.condition_satisfied.connect(_on_condition_satisfied)


func _process(_delta: float) -> void:
	if _lifted or _body == null or speed_penalty_radius <= 0.0:
		return
	var t: float = clampf(_body.velocity.length() / speed_penalty_at_speed, 0.0, 1.0)
	_apply_radius(clear_radius - speed_penalty_radius * t)


func _apply_radius(radius_px: float) -> void:
	_texture.fill_to = Vector2(0.5 + maxf(radius_px, 4.0) / 640.0, 0.5)


func _on_condition_satisfied(key: String) -> void:
	if key != lift_on_key or _lifted:
		return
	_lifted = true
	set_process(false)
	var tween: Tween = create_tween()
	tween.tween_property(_rect, "modulate:a", 0.0, fade_duration)
```

Scene: `CanvasLayer` (script above) → child `TextureRect` named `Fog`, anchored full-rect (`anchors_preset = 15`), `mouse_filter = 2` (ignore — matches the `Floor/Visual` `ColorRect` idiom already in the template), `texture_filter` default is fine at this resolution.

### 2.2 `scenes/days/day_velma.tscn` — the day scene

Built exactly per [HOWTO.md §1](HOWTO.md#1-make-the-scene--5-steps), no chassis changes:

1. **Duplicate `scenes/days/day_template.tscn`** → `scenes/days/day_velma.tscn` (Filesystem dock → right-click → Duplicate — not a hand-written `.tscn`; CLAUDE.md §6 wants scenes built in the editor, not typed out, to keep diffs clean).
2. **Retheme, don't restructure:**
   - `Head` — stays a plain (uncaged) head; position `(560, 306)` as in the template. No `caged = true` — the snag here is vision, not imprisonment, so the head's normal sprite is correct; the vignette carries the theme instead.
   - `Body` — stays at `(100, 320)`.
   - `SpatialGoal` (body key) → rename `GlassesGoal`, position `(300, 320)` — mid-scene, so it reads inside the vignette's clear radius only once the body is already close (the actual "search" challenge).
   - `SpatialGoalMind` (mind key) → rename `ReturnGoal`, position `(500, 320)` — near the head, so walking to it after `GlassesGoal` reads as "bringing them back."
   - Add the new `VisionBlur` scene as a child of the day root (instance `res://scenes/gameplay/vision_blur.tscn`), default exports.
   - `Instruction` label text → something like `"Find the glasses, then bring them back."` (one line, per DESIGN §2.1 "Words" — cut if it reads without it once playtested, per P5 in TASKS.md).
   - `DayManager` script stays the **base** `day_manager.gd` (not a subclass) — this day has no per-need action (nothing like the bridge drop), so `_on_condition_satisfied()`'s default no-op is correct. Confirmed against `platforming_day.gd`, which only subclasses because it drops a bridge on the body need.
3. **The idea itself is already covered by step 2** — both needs are `SpatialGoal`s, the existing "walk here" atom (`spatial_goal.gd`), so there's no new `satisfy()` caller to write beyond `VisionBlur`.
4. **Wire into the run** — `scripts/autoload/game.gd`, `DAY_SCENES` (currently lines 20–24). Open call on exact position — see §4.4; the code change itself is a one-line insert:
   ```gdscript
   const DAY_SCENES: Array[String] = [
       "res://scenes/days/day_velma.tscn",       # new
       "res://scenes/days/day_template.tscn",
       "res://scenes/transition/transition_cage.tscn",
       "res://scenes/days/day_panic.tscn",
       "res://scenes/days/platforming_day.tscn",
   ]
   ```
5. **Prove it** — `tools/smoke_test.sh`. Add a bot plan to `tools/smoke/play_through.gd`'s `plans` dictionary (pattern copied from the existing `day_template` entry) so `play_through` proves the day is completable rather than force-satisfying it:
   ```gdscript
   "res://scenes/days/day_velma.tscn": [
       {"walk_to": 300.0}, {"satisfied": "body"},
       {"walk_to": 500.0}, {"satisfied": "mind"},
   ],
   ```
   (Same shape as `day_template`'s plan, since the two needs are the same atom at different x's — see `tools/smoke/play_through.gd:35-38`.)

---

## 3. Build order (bite-sized)

1. `scenes/gameplay/vision_blur.gd` — write the script above.
2. `scenes/gameplay/vision_blur.tscn` — `CanvasLayer` + `Fog` `TextureRect`, attach the script. Run the scene standalone in the editor (F6) to see the vignette render — no day needed yet, since `_body` being null just skips the speed-penalty branch.
3. Confirm import is clean: `Godot --headless --path . --import`.
4. Duplicate `day_template.tscn` → `day_velma.tscn`, apply the retheme in §2.2 step 2.
5. Add the `DAY_SCENES` line (§2.2 step 4) at whatever index §4.4 lands on.
6. Add the `play_through.gd` plan (§2.2 step 5).
7. `tools/smoke_test.sh` — must be ALL GREEN (`day_lint` checks the day has one head/body/Sun/camera/manager/≥1 need; `day_chain` proves force-satisfy still advances; `play_through` proves the real bot plan works; `day_sunset` proves sunset still fails it).
8. Run it in the editor by hand once — eyeball the vignette actually reads as "blurry, not just dark" and that `GlassesGoal`/`ReturnGoal` aren't invisible under the fog at the start (input/timing/visuals need a human look, per CLAUDE.md §4).
9. Journal entry in `journals/<you>.md` per CLAUDE.md §1, noting which of §4's open calls you resolved and how.
10. If the card in §1 changed while building it, copy the final version into `DESIGN.md` §2.1 as a new row (next to the Bridge (C2) row) so it's locked, and update the Day Plan / cut-order discussion in TASKS.md if the slot order changed.

---

## 4. Open calls — pick before or while building, not silently

### 4.1 Where do the glasses actually fall off?
Brainstorm says "in the intro scene." Today's intro (`scenes/intro/intro.gd`) is a hands-free chase with a TODO for the "whole skeleton → head pops off" beat (CODEBASE.md §6.3, task C4) — it doesn't yet have a moment to stage a glasses-falling beat, and adding one there is intro work, not Velma-day work.
- **Recommended:** skip the intro beat for now — the day scene just opens with the head already bare and the glasses already on the ground (matches how every other day "opens already snagged," DESIGN §2.1). Revisit a literal falling-glasses moment only if/when C4 (the pop-off beat) gets built.
- **Alternative:** block this day on C4 landing first, so the glasses visibly fall in the intro and this day is their sequel. Bigger dependency, more consistent story.

### 4.2 ~~Is "two `SpatialGoal`s" the right read...~~ — **Resolved: real carry mechanic.**
The brainstorm's own scratch note (bottom of `brainstorm.md`) says *"when you give it something (the glasses for instance) we push it to the next scene"* — which reads like the team was already imagining a general **pick-up-and-give** mechanic, possibly shared across days, not specific to Velma. This plan originally recommended the cheaper two-`SpatialGoal`s reading; direct feedback while building asked for an actual pickup, so `scenes/gameplay/glasses.gd` implements the alternative described here: a `Glasses` node the body picks up on overlap (satisfies **body**), that then follows the body until it's carried within reach of the head (satisfies **mind**). It's not yet a generic "give any item to the head" system — `glasses.gd` is Velma-specific — but it's the atom to generalize from if another day wants the same verb.

### 4.3 Keep the speed-linked twist, or cut it?
It's cheap (the `_process` block in `vision_blur.gd` above, ~10 lines) and ties into the DESIGN thesis (moving carelessly makes the "mind" problem worse), but it's not load-bearing — the day works with a static vignette. Cut the `@export var speed_penalty_*` fields and the `_process()` override first if short on time; nothing else in the plan depends on it.

### 4.4 Where does this day sit in `Game.DAY_SCENES`?
**Slot (smahr Sat 14:54):** Velma is after `transition_glasses` in `Game.DAY_SCENES` — intro wears glasses, cage keeps them, panic is caged-with-glasses, glasses transition knocks them off, this day finds them. Head is near the entrance; the climb is later and the room is darker. Today `day_template` plays as day 1, which CODEBASE.md already flags as "a decision for the team," and TASKS.md's D8 (cut order) is explicitly undecided.
- **Recommended:** slot `day_velma` first (as shown in §2.2 step 4), and treat `day_template` as what it always was — a placeholder/reference day — either dropped from the list once Velma is proven, or kept later in the run as a easy warm-up. Don't decide `day_template`'s fate unilaterally here; raise it at the same standup as D8.
- **Alternative:** append `day_velma` after `platforming_day` for now (safest, no reordering risk) and let the whole run order get sorted once at the D8 scope-check meeting rather than twice.

---

## 5. What this plan deliberately does not touch

- No changes to `WinCondition`, `SpatialGoal`, `DayManager`, `WinConditionManager`, or `Events` — every new behaviour is additive (one new node type, one new day file), per the chassis's own promise in HOWTO.md's first line ("a new day is one new file... plus one line in `Game.DAY_SCENES`").
- No shader work, no new art assets, no carry mechanic (see §4.2) — all flagged as stretch/alternative, not part of this plan's critical path.
- No `project.godot` / input map changes — the day uses only `move_left/right`, already bound.
