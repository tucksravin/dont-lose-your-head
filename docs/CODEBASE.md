# Codebase overview — Sat 22 Aug, 08:00

*What is in the repo and how it fits together, with links. Written Sat 08:00 against the integration branch `night/all`; **everything here is on `main` since Sat 16:48** (PR #16 + PR #17). Keep this true when you change a contract; the full per-task story is in `journals/*.md`.*

Godot **4.7.1**, GDScript with static typing, **640×360** pixel art, exported to the web. One run = **intro → the scenes in `Game.DAY_SCENES` → reunion**. Parts find each other by **signals and groups**, never by long node paths, and five autoloads hold the glue.

---

## 0. Ten-second orientation

| you want to… | go to |
|---|---|
| change the order of the run, add a day or a transition | `Game.DAY_SCENES` in [scripts/autoload/game.gd](../scripts/autoload/game.gd) |
| make a new day | [docs/days/HOWTO.md](days/HOWTO.md) (5 steps + the numbers) — copy [scenes/days/day_template.tscn](../scenes/days/day_template.tscn) |
| make a new "need" (a thing the body must do) | a node with a `WinCondition` child that calls `satisfy()` — §5 |
| make a transition into a day | inherit [scenes/transition/transition.tscn](../scenes/transition/transition.tscn), override `_play_arrival()` — §6.2 |
| add a sound | drop `assets/audio/sfx/<cue>.wav` — cue names in `Sfx.CUES` ([scripts/autoload/sfx.gd](../scripts/autoload/sfx.gd)); list in [assets/audio/README.md](../assets/audio/README.md) |
| test without playing | **F1–F10** in any running scene (debug builds) — [scripts/autoload/dev.gd](../scripts/autoload/dev.gd) |
| prove nothing broke | `tools/smoke_test.sh` — §8 |
| ship | `tools/export_web.sh` → `build/web.zip` → itch (README → *Exporting to itch.io*) |

---

## 1. The run, end to end

```mermaid
flowchart LR
  I["intro.tscn<br/>(run/main_scene)"] -- "Game.start_days()" --> D0["day_template.tscn"]
  D0 -- "win → head rolls off" --> T1["transition_cage.tscn<br/>(head rolls downhill, gets caged)"]
  T1 -- "Game.next_day()" --> D1["day_panic.tscn<br/>(calm the caged head)"]
  D1 -- "win" --> Dlock["day_lockdown.tscn<br/>(dodge + pad puzzles)"]
  Dlock -- "win" --> Dwork["day_workout.tscn<br/>(mash kikis off the head)"]
  Dwork -- "win" --> Dmir["day_mirror.tscn<br/>(look flips left/right)"]
  Dmir -- "win" --> D2["platforming_day.tscn<br/>(three steps, bridge, gap)"]
  D2 -- "DayManager → Game.next_day" --> R["reunion.tscn<br/>(dive onto the head)"]
  R -- "next_scene" --> M["main.tscn<br/>(placeholder end)"]
```

**Boot.** `project.godot` → `run/main_scene = scenes/intro/intro.tscn`. The intro is a playable chase ([scenes/intro/intro.gd](../scenes/intro/intro.gd)); when the head leaves the screen it calls `Game.start_days()`.

**The list.** `Game.DAY_SCENES` ([scripts/autoload/game.gd](../scripts/autoload/game.gd)) is the run: `[day_template, transition/transition_cage, day_panic, day_lockdown, day_workout, day_mirror, platforming_day]`, then `Game.REUNION_SCENE`. `go_to(i)` loads entry *i* (or the reunion past the end); `next_day()` advances — and if the current scene was opened straight from the editor (F6), it first looks up where that scene sits, so testing one day still goes on to the right next one.

**How a day is won.** `WinCondition.satisfy()` → `WinConditionManager` (local `condition_satisfied` / `all_satisfied`, plus `Events.condition_satisfied` for HUD/Sfx) → **`DayManager`** releases the head, waits for `head.left_scene`, then `Game.next_day()`. The head rolling off screen *is* the day's outro (DESIGN §2.1). Game is the playlist only — it does not listen for wins.

**How a day fails.** `DayManager.fail(reason)` → [scenes/ui/game_over.tscn](../scenes/ui/game_over.tscn) (pauses, Retry reloads). Sunset is wired in DayManager. Pit (platforming_day), PanicCounter, ThoughtRain hits, KikiSwarm contact, and FlyingKiki hits call `fail()` the same way (sensors find the manager by group `"day_manager"`).

**Transitions** are ordinary entries in the list that play a short beat (the head rolls off down a slope; the player runs the body to it) and end with `Game.next_day()` themselves — put one right before the day it leads into.

---

## 2. Folder map

*All of this is on `main` (merged Sat 16:48). The "from" column says which Friday/overnight branch each part came from — useful only for reading the journals and PRs; it is not where the code lives now.*

| path | what | from |
|---|---|---|
| [project.godot](../project.godot) | 640×360, GL Compatibility, nearest filter + pixel snap, input map (`move_left/right`, `jump`, `interact`, `move_down`, `restart`, `pause`), autoloads | main (+ autoload lines on daykit/sfx) |
| [export_presets.cfg](../export_presets.cfg) | the one "Web" preset (threads off); excludes `tools/*` | main (+ base) |
| [default_bus_layout.tres](../default_bus_layout.tres) | Master → Music, SFX | night/sfx |
| [scripts/autoload/](../scripts/autoload/) | `Events`, `Game`, `Dev`, `Sfx`, `Music` — §3 | main (+ #16: the day list · transition: the transition entry · base: F6 lookup, events.gd note) / daykit (Dev) / sfx (Sfx, Music) |
| [scenes/body/](../scenes/body/) · [scenes/head/](../scenes/head/) · [scenes/sun/](../scenes/sun/) | the three actors every day instances — §4 | main (+ anim; body `jumped`/`landed` on sfx; `caged` head on #16) |
| [scenes/gameplay/](../scenes/gameplay/) | needs + both flow systems, panic, sky drift — §5 | main (+ base/anim) |
| [scenes/days/](../scenes/days/) | one `.tscn` per day (+ `platforming_day.gd`); `day_01.tscn` is a broken leftover — §6.1 | main (+ #16: panic rework, bridge/palette; Instruction label on daykit; sky_drift on anim) |
| [scenes/transition/](../scenes/transition/) | the head-gets-knocked-downhill beat + the cage fork — §6.2 | night/transition |
| [scenes/intro/](../scenes/intro/) · [scenes/reunion/](../scenes/reunion/) · [scenes/ui/](../scenes/ui/) · [scenes/main.tscn](../scenes/main.tscn) | first beat, last beat, game-over card, placeholder end — §6.3 | main (+ sfx/anim on reunion.gd, sfx on game_over.gd) |
| [assets/sprites/](../assets/sprites/) · [assets/palette/](../assets/palette/) · [assets/audio/](../assets/audio/) · [assets/fonts/](../assets/fonts/) | art (+ Aseprite sources), the 9-colour palette, audio drop folders (empty), fonts (empty) — §7 | main / sfx |
| [tools/](../tools/) | `smoke_test.sh` + `smoke/*.gd`, `export_web.sh` — §8 | base (+ transition/daykit/sfx edits under smoke/) / main (export_web.sh) |
| [docs/](.) · [journals/](../journals/) | DESIGN, TASKS, dependencies, HOWTO, this file, the overnight report; one journal per person — §9 | main / #16 / base / daykit / transition (DESIGN §2.1 Transitions row) |
| `build/` | export output, git-ignored except `build/.gdignore` | — |

---

## 3. Autoloads — [scripts/autoload/](../scripts/autoload/)

Autoloads are nodes Godot adds under the root before any scene, by name, in this order: **Events, Game, Dev, Sfx, Music**. In `-s` script mode (the smoke tests) they exist at runtime but aren't compile-visible — reach them with `Smoke.autoload(tree, "Game")` (= `tree.root.get_node_or_null("Game")`, [tools/smoke/smoke_lib.gd](../tools/smoke/smoke_lib.gd)).

| autoload | file | job | surface |
|---|---|---|---|
| **Events** | [events.gd](../scripts/autoload/events.gd) | the cross-scene signal bus — declares, never emits | `condition_satisfied(key)`, `day_completed`, `day_failed(reason)`, `sunset` (declared, **never emitted** — the Sun's local `sunset` is what's used) |
| **Game** | [game.gd](../scripts/autoload/game.gd) | the playlist — owns the run order and scene changes (one bypass: GameOver's Retry calls `reload_current_scene()` itself — [scenes/ui/game_over.gd](../scenes/ui/game_over.gd)) | `DAY_SCENES`, `REUNION_SCENE`, `current_day`; `start_days()`, `go_to(i)`, `next_day()`, `restart_day()`, `change_scene(path)`. Does **not** listen to `Events.day_completed` / `day_failed` — DayManager owns those. |
| **Dev** | [dev.gd](../scripts/autoload/dev.gd) *(night/daykit)* | dev keys + overlay, **debug builds only** (inert in the web export) | F1/F2/F3 satisfy body/mind/all · F4 fail · F5 restart · F6/F7 prev/next in the run · F8 reunion · F9 overlay (needs ✓/✗, sun %, panic, body) · F10 slow-mo. Registers `debug_*` actions at runtime so the input map stays gameplay-only |
| **Sfx** | [sfx.gd](../scripts/autoload/sfx.gd) *(night/sfx)* | sound effects by name; silent until a file exists | `CUES` (16, the single source of truth), `play(cue, pitch_scale = 1.0) -> bool`, `missing()`, `has_file()`, signal `played(cue)`. Wires itself by **signal shape** as nodes enter the tree: body `jumped`/`landed`, head `released`, Sun (has `sunset` + `day_length` → a one-shot `sunset_warning` timer 5 s before day end), PanicCounter `panic_changed`/`calmed`, DayManager `day_failed`, WinConditionManager `condition_satisfied`/`all_satisfied`; plus the Events bus. **Web:** audio can't start before the first click/keypress — and the intro plays hands-free, so the intro is silent on the web until day 1 (X4, a press-any-key screen, would fix that) |
| **Music** | [music.gd](../scripts/autoload/music.gd) *(night/sfx)* | one looping track per scene, 0.8 s crossfade; silent until a file exists | a scene root's `music_track` export → `TRACKS` map by path → `day` for anything in `scenes/days/` → silence |

---

## 4. Actors — body, head, sun

Every day instances all three. None of them knows about anything else by path: they add themselves to **groups** (`body`, `head`) or are found by **what they have** (the Sun by its `sunset` signal — DayManager checks just that; `sky_drift` also wants `progress()`; `Sfx`/`Dev` also want `day_length`).

**Body** — [scenes/body/body.tscn](../scenes/body/body.tscn) / [body.gd](../scenes/body/body.gd). `CharacterBody2D`, 24×32 collision, origin at the **feet**; `Visual` is an `AnimatedSprite2D` on [assets/sprites/body_frames.tres](../assets/sprites/body_frames.tres) (`idle`, `walk`, `throw`; `throw` unused) at 2×, `centered = false`, `offset (-16,-32)`. Exports `speed 150`, `jump_velocity -300`, `gravity 980`, `move_sign 1` (set to −1 to swap left/right; mirror day), `invert_vertical` (jump reads `move_down` / ↓) → **max rise 45.9 px, hang 0.61 s, 92 px reach**. Signals `jumped`, `landed`. `play_throw()` plays the `throw` sheet (mirror day; `_process` will not overwrite it). `is_scripted = true` hands control to a cutscene (intro, transition) which must then drive velocity + `move_and_slide()` itself. Group `body`. Child `Juice` ([body_juice.gd](../scenes/body/body_juice.gd)): breathing, stretch/squash on `jumped`/`landed`, lean — scale/rotation only, `reset()` for cutscenes; delete the node and the body is as before.

**Head** — [scenes/head/head.tscn](../scenes/head/head.tscn) / [head.gd](../scenes/head/head.gd) (`class_name Head`). A **frozen** `RigidBody2D` (kinematic freeze — scripted, not simulated, DESIGN §2.1), 28×28 collision centred — **solid to the body**. `Visual` on [head_frames.tres](../assets/sprites/head_frames.tres): `loose`, `look_left` / `look_right` (head_keyed f1 / f3), `imprisoned` (4-frame cage loop), `wink`. Exports `exit_speed 180`, `exit_direction RIGHT`, `spin_speed 360`, `exit_margin 64`, `caged` (plays the cage loop), `jitter_px`/`jitter_full_agitation` (*anim*: sprite-only shake). `release()` (idempotent) → translates + spins off screen → `left_scene`. `look(dir)` plays look_left (−1) / look_right (+1) / loose (0); no-op if caged. `attach(carrier, offset)` / `detach()` — follow a node without reparenting (lockdown carry); collision off while attached; `offset.x` flips with the carrier's `Visual.flip_h`. `set_solid(bool)`. Signals `released`, `left_scene`. `set_agitation(x)` scales the cage loop speed (and the shake). Group `head`. Placement: y = 306 sits on a y = 320 floor.

**Sun** — [scenes/sun/sun.tscn](../scenes/sun/sun.tscn) / [sun.gd](../scenes/sun/sun.gd). The day timer: arcs `start_position → end_position` over `day_length` (**30 s**), `arc_height 40`, emits local `sunset` once; `progress() -> float` (0→1); gentle scale pulse (`pulse_amount`, *anim*). Who uses it: `DayManager` connects to `sunset` (fail the day); `Sfx` reads `day_length` and arms a timer for `sunset_warning` 5 s before the end; [sky_drift.gd](../scenes/gameplay/sky_drift.gd) polls `progress()` each frame (*anim*; a `Background` Polygon2D lerps its own colour to `dusk`).

---

## 5. Needs and day flow — [scenes/gameplay/](../scenes/gameplay/)

The atom is **`WinCondition`** ([win_condition.gd](../scenes/gameplay/win_condition.gd), `class_name`): a flag with `key` = `"body"` | `"mind"`, `satisfy()` (idempotent), signal `satisfied(key)`, `is_satisfied`. DESIGN §2.1: one body + one mind need per day.

**A need node** owns a `WinCondition` child and calls `satisfy()` when its thing happens — it never loads scenes or decides the day is *won*. Fail goes through `DayManager.fail()`. Two exist:
- **SpatialGoal** — [spatial_goal.tscn](../scenes/gameplay/spatial_goal.tscn) / [.gd](../scenes/gameplay/spatial_goal.gd): an `Area2D` (32×32) that satisfies on a `CharacterBody2D` entering; set `key` on the instance (forwarded to the child). Placeholder rect, green for `body` / light-green for `mind` (`body_color` / `mind_color` exports); pops when met (*anim*).
- **PanicCounter** — [panic_counter.tscn](../scenes/gameplay/panic_counter.tscn) / [.gd](../scenes/gameplay/panic_counter.gd) (`class_name`): panic starts at 15, rises 6/s while the body moves, holds 0.5 s, falls 3/s when still; **0 satisfies `mind`**, 30 fails the day (`DayManager.fail("panic")` via group `"day_manager"`); drives `head.set_agitation()`; signals `panic_changed(int)`, `calmed`; group `panic_counter`. [panic_label.gd](../scenes/gameplay/panic_label.gd) is its placeholder readout.
- **PuzzleChain + AnswerPad + ThoughtRain** — Lockdown's needs: [puzzle_chain.tscn](../scenes/gameplay/puzzle_chain.tscn) (two `WinCondition` children; last correct pad satisfies body + mind; `start()` after the setup beat), [answer_pad.tscn](../scenes/gameplay/answer_pad.tscn) (`class_name AnswerPad`, group `answer_pad`; stand then press `interact` / E to submit; hidden until seated), [falling_thought.tscn](../scenes/gameplay/falling_thought.tscn) + [thought_rain.gd](../scenes/gameplay/thought_rain.gd) (hit → `fail("hit")`; `autostart` off until seated; lockdown instance `fall_speed 320`, `interval 0.32`, `burst 2`). Setup lives on [day_lockdown.gd](../scenes/days/day_lockdown.gd) (pick up → `head.attach(body)` → bar + pedestal → `detach()` + seat). Win: `_before_head_release()` tips the pedestal +90° (clockwise, toward the exit), then `head.release()`.
- **Barbell + KikiSwarm** — Workout's needs: [barbell.tscn](../scenes/gameplay/barbell.tscn) (`interact` pickup, follows the body, `pump()` on mash), [kiki_swarm.tscn](../scenes/gameplay/kiki_swarm.tscn) (two `WinCondition` children; `kiki_frames.tres`; pressure 0 satisfies body+mind, 1 → `fail("kiki")`; creep after `begin()`; `StaticBody2D` circle blocks the walk to the head). Director: [day_workout.gd](../scenes/days/day_workout.gd).
- **Mirror World** — two `WinCondition` children on [day_mirror.tscn](../scenes/days/day_mirror.tscn); director [day_mirror.gd](../scenes/days/day_mirror.gd) toggles `Head.look` + `Body.move_sign` + `invert_vertical`. [flying_kiki.tscn](../scenes/gameplay/flying_kiki.tscn) flies out of the glass (hit → `fail("kiki")`). `interact` / flipped `jump` at the glass satisfies both; `_before_head_release()` throws the glass, then DayManager `release()`s the head after it.

**To write a new need:** a node with a `WinCondition` child (set/forward `key`), call `condition.satisfy()` once. `WinConditionManager` discovers it by class at `_ready` — no wiring for the win. A need that can *fail* the day calls `DayManager.fail()` (find group `"day_manager"`).

**The manager** — [win_condition_manager.gd](../scenes/gameplay/win_condition_manager.gd) + [day_manager.gd](../scenes/gameplay/day_manager.gd). Used by every day. Reports via local signals → DayManager (`_on_condition_satisfied(key)` for per-need actions, e.g. drop the bridge). If the day root has `_before_head_release()`, DayManager awaits it before `head.release()` (lockdown's pedestal tip). Fail → game-over card. Sunset wired on DayManager. Next scene → `Game.next_day()`. A day can sit anywhere in `DAY_SCENES`. The old `WinConditions` + `Game._on_day_completed` path is deleted.

---

## 6. Scenes

### 6.1 Days — [scenes/days/](../scenes/days/)

| scene | in the run | system | needs | head | text |
|---|---|---|---|---|---|
| [day_template.tscn](../scenes/days/day_template.tscn) | [0] | DayManager | body (500,320) + mind (200,320) SpatialGoals | loose at (560,306) | "Template day: touch both boxes." |
| [day_panic.tscn](../scenes/days/day_panic.tscn) | [2] | DayManager | **mind only** (PanicCounter) — DESIGN wants both | `caged = true` at (560,306) | "Your head is panicking in its cage…" |
| [day_lockdown.tscn](../scenes/days/day_lockdown.tscn) | [3] | DayManager | setup (carry head to pedestal) then body+mind via PuzzleChain (4 pad puzzles, `interact`); ThoughtRain fails on hit (fast, burst 2); win tips the pedestal | loose in the middle (320,306), seated at (560,258) | "Walk to the head and press E." then the puzzle line |
| [day_workout.tscn](../scenes/days/day_workout.tscn) | [4] | DayManager | barbell pickup then mash `jump` vs KikiSwarm (creep-back, pumps bar); kiki circle blocks the head; fail sunset or `kiki` | loose at (560,306) | "Walk to the barbell and press E." then mash Space |
| [day_mirror.tscn](../scenes/days/day_mirror.tscn) | [5] | DayManager | jump kikis from the glass; `interact` throws it; look-at-glass inverts walk + jump (↓ hops); fail sunset or `kiki` | on platform at (572,258) | "Jump the thoughts. E at the glass throws it. Arrows flip with the head." |
| [platforming_day.tscn](../scenes/days/platforming_day.tscn) + [.gd](../scenes/days/platforming_day.gd) | [6] | DayManager subclass | body = HighGoal on step 3 (drops the bridge) · mind = FarGoal across the gap | loose at (450,306) — **a solid block on the path**, the player jumps it | "Climb to the high green box — it drops a bridge." |
| [day_01.tscn](../scenes/days/day_01.tscn) | — | — | — | — | **broken**: references a missing `day_01.gd`; superseded by platforming_day; parked in [tools/smoke/known_broken.txt](../tools/smoke/known_broken.txt) |

Every day = `Background` (Polygon2D, sky `#988277`; *anim* adds `sky_drift.gd` on template/panic) · `Camera2D` at (320,180), fixed · floor top at **y = 320** · Body · Head · Sun · a manager · needs · an `Instruction` Label. The template ships as the first day today — a decision for the team.

### 6.2 Transition — [scenes/transition/](../scenes/transition/)

[transition.tscn](../scenes/transition/transition.tscn) / [transition.gd](../scenes/transition/transition.gd): **one straight slope** (−40,100)→(740,360) (one `StaticBody2D` + `CollisionPolygon2D`). The head (an `AnimatedSprite2D` on head_frames — *not* head.tscn; a frozen RigidBody2D under a PathFollow2D fights it) **sits at rest** at the start of a `Path2D`/`PathFollow2D` 15 px above the ground (x=240) that runs to x=560; the body spawns at x=50. **Timeline (Sat afternoon, Tucker — the head is not fleeing; the situation is what knocks it rolling):** waits until the body is within `trigger_distance` 100 px — the "I almost caught up to you" beat — or `arrival_wait` 4 s → `_play_arrival()` (the fork's situation; the cage drops) → `head_rolled` → the head rolls (Tween on `progress`: `roll_time` 1.0 s at constant speed for `brake_ratio` 0.85 of the path, then `brake_time` 0.3 s easing out; the sprite spins whole turns over the path — rolling without slipping rounded so it stops upright) → ends only once the body has reached the stopped head (`arrive_distance` 40 px; controls off via `is_scripted`, settles; `body_arrived`) → `hold_after_arrival` 0.6 s → `fade_duration` 0.4 s → `Game.next_day()`. **The body is the player's** (Sat 08:40 — body.gd untouched; the scene only sets `floor_snap_length` = `body_floor_snap` 8). ~4 s if the player runs straight; open-ended if not (`HUD/Instruction` says to go after it; placeholder copy).

**Fork recipe (decided Fri 22:50 — inherited scenes):** *Scene → New Inherited Scene* from `transition.tscn` → save as `transition_<situation>.tscn`; a script `extends "res://scenes/transition/transition.gd"` overriding only `_play_arrival()`; add props as new nodes; put it in `DAY_SCENES` right before its day. Worked example: [transition_cage.tscn](../scenes/transition/transition_cage.tscn) / [.gd](../scenes/transition/transition_cage.gd) — a second `imprisoned` sprite drops onto the resting head (no new art), the knock sends the caged head tumbling down the slope **and clean off the right edge** (three property overrides on the inherited scene: HeadPath's curve runs to x=720, `roll_time` 1.6, `brake_ratio` 1.0 — no code); the body runs off after it, and the base's "body reached the head" end then fires off screen → fade → day_panic. ~5 s running straight.

### 6.3 Intro, reunion, UI, placeholder

- **Intro** — [scenes/intro/intro.tscn](../scenes/intro/intro.tscn) / [.gd](../scenes/intro/intro.gd): `HeadBlob` (CharacterBody2D, `head_side.png`) runs right on its own and leaves; **the player has to chase it off the right edge themselves** (Sat evening: no scripting moves the body; the scene changes only once the body is `exit_margin` 24 px past the edge, then `exit_delay` 0.4 s → `Game.start_days()`). It has a **Sun** like every day (found by its `sunset` signal): sunset before you have left → `Game.restart_day()` reloads the intro. The bot's plan is `run right`. Its `@export next_scene` is **never read**. The "head pops off" beat is a TODO in the file.
- **Reunion** — [scenes/reunion/reunion.tscn](../scenes/reunion/reunion.tscn) / [.gd](../scenes/reunion/reunion.gd): walk to the upside-down head, `interact` within 64 px → dive Tween (`dive_rise/fall/apex`, `landing_offset (0,-56)`) → fade → `next_scene` = **[scenes/main.tscn](../scenes/main.tscn)** — the old input-test placeholder. **There is no end card yet.** [scenes/reunion/preview/sprites_preview.tscn](../scenes/reunion/preview/sprites_preview.tscn) is a standalone sprite check (ships in the export; harmless).
- **Game over** — [scenes/ui/game_over.tscn](../scenes/ui/game_over.tscn) / [.gd](../scenes/ui/game_over.gd): CanvasLayer, `show_over()` pauses, Retry reloads. Every day instances it.

---

## 7. Assets

- **Sprites** — [assets/sprites/](../assets/sprites/): `body_idle/walk/throw.png` (32×32 frames) + `body_frames.tres`; `head_front/side/keyed.png` (16×16; keyed = 8 frames: look L/C/R, wink, 4-frame cage) + `head_frames.tres`; `sun.png`; `bridge.png` (**24×8 tile, posts every 6 px** — a run that starts *and* ends on a post is 6n+2 wide; exported with `--crop`, not `--trim`). Sources in `src/*.aseprite`. Rule: **no generative art**; render at integer 2×. [README](../assets/sprites/README.md), [CREDITS](../assets/sprites/CREDITS.md).
- **Palette** — [assets/palette/](../assets/palette/): Gooseberry Ghost + bone shadow + violet ramp (12): sky `#988277` · ground `#006a3d` · bone `#f1ffaf` · shadow `#cdcd99` · outline `#201c02` · greens `#25c04b` `#b2f167` · browns `#645543` `#45381c` · violet ramp `#5e2d8c` `#8a4fb5` `#c79df2` (intrusive thoughts / kikis — `kikis.png`). Colour floats in `.tscn`: the editor writes full precision; a hand-typed 6-digit `0.596078` **renders correctly** (GPU rounds; measured Sat 17:xx, all 10 swatches exact) — it is only off by one byte through `Image.set_pixel`/`fill` (truncates → `#978277`) and fails exact `==` (use `is_equal_approx`).
- **Audio** — [assets/audio/README.md](../assets/audio/README.md) *(night/sfx)*: `sfx/<cue>.wav|ogg` (16 cues, WAV mono 44.1k) and `music/<track>.ogg` (`intro`, `day`, `transition`, `reunion`, or a day's `music_track`). Both folders are empty by design; `Sfx` prints the missing-cue list at boot (`Sfx: 16/16 cues have no file yet — …`); Music reports nothing — a missing track is just silence.
- **Fonts** — empty; all text is antialiased TTF — the only off-palette pixels in the palettised scenes (intro, day_template, day_panic, transition, platforming_day, reunion). Still off-palette: `game_over.tscn`'s black dim/title and `main.tscn`'s `#1b1b2a` background.

---

## 8. Tools — [tools/](../tools/)

**[tools/smoke_test.sh](../tools/smoke_test.sh)** runs `--import` then six `SceneTree` scripts headless (`godot --headless --path . -s tools/smoke/<name>.gd`); red on any `FAIL`, any engine `ERROR`/`Parse Error`, or a missing `SMOKE PASS`. `tools/smoke_test.sh <suite>` runs one; `--web` also exports.

| suite | proves |
|---|---|
| [load_all](../tools/smoke/load_all.gd) | every scene/script/resource loads; every `ext_resource` path exists |
| [day_lint](../tools/smoke/day_lint.gd) | every `scenes/days/*.tscn` has one head, one body, a Sun, a camera, WinConditionManager + DayManager + game-over overlay, ≥1 need; `DAY_SCENES` entries exist |
| [day_chain](../tools/smoke/day_chain.gd) | force-satisfy each day → head releases → next scene → reunion |
| [day_sunset](../tools/smoke/day_sunset.gd) | each day reacts to sunset; a *won* day ignores it |
| [play_through](../tools/smoke/play_through.gd) | **a bot presses the real input actions and plays intro → every scene → end** (~32 s); a day with no plan is force-satisfied with a warn — add a 3-line plan when the layout is stable |
| [audio](../tools/smoke/audio.gd) | buses exist, cue names legal, cues fire at the right moments (jump/land/need/won/release/sunset), a day picks the `day` track |

[smoke_lib.gd](../tools/smoke/smoke_lib.gd) holds the helpers and two hard-won rules: under `-s` the parser doesn't know autoload names (use `Smoke.autoload(tree, "Game")`), and lambdas that outlive a scene must capture **instance ids, not nodes** (`scene_id()`). A third — nothing is in the tree during `SceneTree._initialize()`, so await a frame before touching autoloads — is the comment at the top of [day_chain.gd](../tools/smoke/day_chain.gd). [known_broken.txt](../tools/smoke/known_broken.txt) lists scenes allowed to be broken — one justified line each.

**[tools/export_web.sh](../tools/export_web.sh)**: headless import → `--export-release Web` → `build/web.zip`. `GODOT=/path tools/export_web.sh` on a non-default install (same for smoke_test.sh).

---

## 9. Docs — [docs/](.)

[DESIGN.md](DESIGN.md) (§2 Locked = the decisions; §3 open questions) · [TASKS.md](TASKS.md) (IDs, owners, done-when; reassessed Sat 08:00) · [task-dependencies.md](task-dependencies.md) (what blocks what, Mermaid) · [days/HOWTO.md](days/HOWTO.md) (make a day + the numbers) · [days/brainstorm.md](days/brainstorm.md) (day-card scratch ideas — DESIGN §3.7 points here) · [overnight-2026-08-22.md](overnight-2026-08-22.md) (the night's branches + the stand-up agenda) · [../README.md](../README.md) (setup, config, input map, smoke, export, git) · [../CLAUDE.md](../CLAUDE.md) (LLM working agreement) · [../journals/](../journals/) (one per person, append-only) · [../meeting-notes-friday.md](../meeting-notes-friday.md) / [../brainstorm.md](../brainstorm.md) (sources).

---

## 10. Load-bearing names — grep before you rename

These are matched by string (`has_signal` / `has_method` / `get` / `call` / group names) or referenced across files in more than one place (Game, Dev, Sfx, DayManager, PanicCounter, the smoke suite) — grep before you rename:

- **Groups:** `body` (body.gd), `head` (head.gd), `panic_counter` (panic_counter.gd), `day_manager` (day_manager.gd)
- **Signals:** body `jumped` `landed` · head `released` `left_scene` · sun `sunset` · WinCondition `satisfied` · PanicCounter `panic_changed` `calmed` · DayManager `day_failed` · WinConditionManager `all_satisfied` `condition_satisfied`
- **Properties / methods:** sun `day_length` `progress()` · head `release()` `set_agitation()` · WinCondition `key` `is_satisfied` `satisfy()` · DayManager `fail()` · WinConditionManager `register()` · transition `_play_arrival()` · `Game.DAY_SCENES` `REUNION_SCENE` `start_days()` `go_to()` `next_day()` `restart_day()` · body `speed` `gravity` (read by `get()` in transition.gd's pull-up) · body `is_scripted` (set from outside by intro.gd and transition.gd)
- **Paths by convention:** `scenes/days/*.tscn` (lint, bot fallback, Music's `day` track) · `scenes/transition/*.tscn` (lint) · `assets/audio/sfx/<cue>.wav` (or `.ogg`), `assets/audio/music/<track>.ogg`

---

## 11. Numbers

640×360 · floor top y = 320 · body speed 150 / jump −300 / gravity 980 → rise 45.9 px, reach 92 px · head 28×28, exits right at 180 px/s spinning 360°/s · sun 30 s · goal 32×32 · panic 15 → 0 to win, 30 to fail. Full card: [days/HOWTO.md §2](days/HOWTO.md).

---

## 12. Rough edges worth knowing (most are in TASKS / the stand-up agenda; the dead `Events.sunset` / intro `next_scene` and the `origin/main` lag are only noted here)

- One flow system (DayManager + WinConditionManager; Game is the playlist) · the run **ends on the placeholder `main.tscn`** · `day_template` plays as day 1 · `day_01.tscn` is broken · the head blocks the path in platforming_day · `Events.sunset` and `intro.gd`'s `next_scene` are dead · `restart`/`pause` are bound but nothing in gameplay reads them (only the placeholder `main.gd` echoes them to its label) · D12 (step 1 clips the body's head; the jump can't be raised without retuning) · the comment in `panic_label.gd` · four declared cues (`step`, `cage`, `thud`, `bridge_drop`) have no caller yet · `origin/main` is 30 commits behind `night/all`.
