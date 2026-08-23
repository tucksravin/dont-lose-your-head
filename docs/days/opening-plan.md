# Opening — implementation plan (landing screen → new intro → bird transition)

**Asked for by Tucker, Sat evening.** In his words: *"a landing screen in palette with 'Let the Intrusive Thoughts In' as a replacement for the typical 'click to play' … with the guy (head and all) walking in place underneath. After we click it … the guy ends up next to a slope, and then a swarm of kikis come panic the head until it gets to the point where it falls off and goes down the slope. We have a transition scene — just use the controls to chase the head down the hill until a bird grabs the head and flies off to the right with it. Then we're in the first panic scene."*

**Four calls Tucker made up front** (asked before speccing, per CLAUDE.md §2):

| question | answer |
|---|---|
| Which panic day does the bird hand into? | **`day_panic_still`** (the tree). Its head already starts "stuck in a tree on the right-edge cliff" — the bird stashing it there explains that setup for free. |
| Who walks the guy to the slope? | **Fully scripted** until the head falls. The player takes over for the chase, in the transition. |
| How does the head come off? | **Kikis swarm, a panic meter fills, the head pops off** — reusing `KikiCloud` + `PanicCounter`, so the opening teaches the panic mechanic before it matters. |
| Landing screen contents | **Game title + button** (+ the guy walking in place). It becomes the boot scene. |

**Scope:** ~2.5–3 h — three new scenes, one small base-scene hook, one playlist entry. Over the CLAUDE.md §7 two-hour line, flagged here.

**Needed from Tucker:** the **bird sprite**. What the code wants: a horizontal sheet at integer 2×, palette-only, with a `fly` loop and — if it's cheap — a `carry` variant holding the head. Until it lands, the bird is a placeholder rectangle in the palette's violet so the beat can be built and timed; swapping it in afterwards is the same three lines as `button.png` and `tree.png` (sheet → `bird_frames.tres` → the `AnimatedSprite2D`).

---

## 1. Landing screen — `scenes/ui/title.tscn` / `title.gd`

- Palette background (sky `#988277`), title **"Don't Lose Your Head"** as a `Label` in bone `#f1ffaf` with the `#201c02` outline every in-game label uses (`outline_size` 4), and a `Button` reading **"Let the Intrusive Thoughts In"**.
- The button is the same node and styling as `scenes/ui/game_over.tscn`'s Retry — a plain `Button` in a `CenterContainer`/`VBoxContainer` with `custom_minimum_size` (wider than 140 for the longer text) — so the two screens match without inventing a theme.
- **The guy walking in place:** an instance of `body.tscn` with `is_scripted = true` and `velocity.x` set to its walk speed. `body.gd`'s `_process` picks the `walk` animation off `velocity`, but scripted mode never calls `move_and_slide()` — so he walks on the spot with no new art and no new code. `head.tscn` sits on top via `Head.attach(body, carry_offset)`, so it is the same guy the game uses, glasses and all.
- Pressing the button → `Game.change_scene("res://scenes/intro/intro.tscn")`.
- `project.godot`'s `run/main_scene` moves from the intro to this. **That is a `project.godot` edit — flagging it per CLAUDE.md §8** even though it is not a rendering/display setting.

## 2. New intro — `scenes/intro/intro.tscn` / `intro.gd` (rewrite)

The current intro (head-blob runs off, player chases it off the right edge) is replaced wholesale. Layout: flat ground on the left, a **slope** on the right — the same shape as the transition's hill so the two read as one place.

Beats, all scripted (no input):
1. The guy walks in from the left and stops at a mark next to the slope's crest. Movement is `velocity` + `move_and_slide()` driven by the script with `is_scripted = true`, so it uses the real walk animation and real collision.
2. A **`KikiCloud`** (smahr's, `scenes/gameplay/kiki_cloud.gd`) closes in around the head, its ring tightening as pressure rises — the same node the tree day uses.
3. A **`PanicCounter`** fills. The intro listens to `panic_changed` and runs its own ending at max rather than leaning on `_fail_if_maxed()`, which looks up the `day_manager` group — there is no DayManager here, so it no-ops; the intro must not depend on it.
4. At max: the head **pops off** — `Head.detach()`, a small hop, it lands, rolls right and over the crest, and the scene hands off with `Game.start_days()`.

Sun/timer: **none.** The opening is a cutscene; a sunset failing it would be nonsense. (The current intro has a Sun — that goes.)

## 3. Bird transition — `scenes/transition/transition_bird.tscn` / `.gd`

An inherited scene off `transition.tscn`, exactly like `transition_cage`. The base already gives us: one slope, the head resting at the top, the player driving the body, the beat ending when the body reaches the head, then fade → next day.

**One small change to the base** (announced per CLAUDE.md §6, since the base is shared): a second virtual hook, **`_play_exit()`**, called *after* the body has reached the stopped head and *before* the fade. `_play_arrival()` is the situation that starts the head rolling; `_play_exit()` is what happens once you have caught up to it. Default: no-op, so `transition_cage` and `transition_glasses` are unaffected.

`transition_bird.gd` then overrides:
- `_play_arrival()` — nothing to explain, the intro already knocked the head loose, so it returns immediately and the head rolls straight down the hill;
- `_play_exit()` — a **bird** swoops in, snatches the head off the ground, and flies off to the **right** carrying it, then the fade runs.

## 4. Playlist — `scripts/autoload/game.gd`

`DAY_SCENES` gains `transition_bird.tscn` at the front, so the whole run becomes:

```
title.tscn  →  intro.tscn  →  [ transition_bird → day_panic_still → transition_cage → day_panic → … ]
                              ^ Game.start_days() enters DAY_SCENES here
```

## 5. What could bite

- **`Game.restart_day()` in the intro.** With no Sun and no DayManager nothing calls it, but `current_day` is −1 during the intro, so a stray restart just reloads the scene. Harmless; noted so nobody "fixes" it.
- **The head is a frozen `RigidBody2D`.** The pop-off must move it by tween/position like every other cutscene here — never by unfreezing it (transition.gd's header records why: a physics head under a moving parent fights it).
- **Two slopes must match.** The intro's crest and the transition's hill are separate scenes; if their shapes differ the cut will read as a jump. Same polygon, same numbers, copied deliberately.
- **Kikis are cosmetic in the opening.** `KikiCloud` places sprites; it has no collision, so nothing can "hit" the player here. The panic meter is the whole threat.
