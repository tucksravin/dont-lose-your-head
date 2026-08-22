# How to make a day (and what the chassis can do)

The promise (TASKS.md T8): **a new day is one new file that runs end to end with no edits elsewhere** — plus one line in `Game.DAY_SCENES`. This page is that note, and the numbers you design against.

## 1. Make the scene — 5 steps

1. **Duplicate `scenes/days/day_template.tscn`** → `scenes/days/day_<name>.tscn` (Filesystem dock → right-click → Duplicate). One owner per file (DESIGN §4.3).
2. **Keep the bones, change the world.** The template already has everything a day needs — keep these nodes, move them, retheme them:
   - `Background` (Polygon2D, sky `#988277`) · `Camera` (fixed at 320,180 — do not move it, DESIGN §2.1)
   - `Floor` (StaticBody2D + ColorRect, ground green `#006a3d`, top at **y = 320**)
   - `Body` (instance of `body.tscn`; its origin is its **feet** — put it at y = 320 to stand on the floor)
   - `Head` (instance of `head.tscn`; origin is its **centre**, 28 px box — y = 306 sits on the floor). Tick `caged` for the head behind bars. It stays frozen until every need is met, then rolls off to the right (`exit_direction`/`exit_speed` per instance).
   - `WinConditions` (the manager — finds every `WinCondition` anywhere in the scene; emits `Events.day_completed` when the last one lands; fails the day at sunset)
   - `SpatialGoal` ×2 (Area2D "get the body here" — set `key` = `body` / `mind` on each instance; the green box is placeholder art)
   - `Sun` (the 30 s timer; `day_length` per instance)
   - `Instruction` (Label, top of screen — the one line of text the day is allowed, DESIGN §2.1 "Words")
3. **Add the day's idea.** A need that isn't "walk here" = any node that calls `satisfy()` on a `WinCondition` child with the right `key`. `scenes/gameplay/panic_counter.tscn` is the worked example of a non-spatial need (it satisfies `mind` when panic reaches 0, and fails the day at max panic via `Events.day_failed`). Keep the tunables as `@export`s on your node.
4. **Put it in the run:** add the path to `Game.DAY_SCENES` in `scripts/autoload/game.gd` (order = play order; a transition scene goes right before the day it leads into; see the ordering note in that file). Press **F7** in any running scene to skip to it.
5. **Prove it:** `tools/smoke_test.sh`. `day_lint` checks the bones; `play_through` will *force-satisfy* a day it has no plan for and warn — add a 3-line plan in `tools/smoke/play_through.gd` once the layout is stable so the bot proves it's completable.

Then press **F9** in the running game for the overlay (needs ✓/✗, sun %, body position), **F1/F2** to satisfy a need, **F4** to fail, **F5** to restart. Dev keys exist only in debug builds — never in the web export.

## 2. What the chassis can do — design against these numbers

| | |
|---|---|
| Screen | **640 × 360**, fixed camera, 1 world px = 1 screen px (2× on a 1280×720 window) |
| Floor convention | top of the ground at **y = 320**; 40 px of ground below it |
| Body | `speed` **150 px/s** · `jump_velocity` **−300** · `gravity` **980** → **max rise 45.9 px** (a 36 px step is comfortable, 48 is impossible) · hang time **0.61 s** → **92 px horizontal reach** from a standing jump · collision **24 × 32** (feet at origin) · sprite 26×38 on screen · walks up/down slopes ≤ 45° out of the box |
| Head | 28 × 28 box, centred · states: `loose` (plain), `imprisoned` (4-frame cage loop; `caged = true`), `wink` · `set_agitation(x)` scales the cage loop speed · **solid to the body** — if it sits on the path to a goal the player has to jump it (platforming_day does this, x=450) |
| Goals | `SpatialGoal` is a 32×32 area; origin at its bottom-centre (put it at floor y to sit on the ground) |
| Sun | **30 s** per day by default · arcs left→right across the top · `sunset` fails the day (restart) — a won day ignores it |
| Needs | one `body` + one `mind` per day (DESIGN §2.1). Both must be met; order is free. |
| Palette | Gooseberry Ghost + bone shadow + violet — `assets/palette/`. Sky `#988277` · ground `#006a3d` · bone `#f1ffaf` · outline `#201c02` · greens `#25c04b` / `#b2f167` · browns `#645543` / `#45381c` · **violet ramp `#5e2d8c` / `#8a4fb5` / `#c79df2` for intrusive thoughts / kikis only**. Let the editor write the colour floats (it stores full precision, `0.596078431372549`); a hand-typed 6-digit `0.596078` **renders correctly** (the GPU rounds — measured Sat 17:xx) but is floored to the wrong byte by `Image.set_pixel`/`fill` (→ `#978277`) and fails exact `==` against `Color("#988277")` — use `is_equal_approx`. |
| Sprites | `assets/sprites/` — body: `idle` `walk` `throw` · head: `loose` `imprisoned` `wink` · `bridge.png` (24×8 tile; posts every 6 px — a run that starts *and* ends on a post is 6n+2 wide) · `sun.png`. No generative art — if a day needs a prop, ask Tucker. |
| Fail | `Events.day_failed("why")` → `Game.restart_day()` (instant reload). Sean's `DayManager` days show a game-over card instead — two systems coexist until the team unifies them (Saturday agenda). |
| Transitions | head-rolls-down-the-hill beat between days: `scenes/transition/` — fork recipe in `transition.gd`'s header (inherited scenes). |

## 3. Two ways a day is wired today (pick one, don't mix)

- **`WinConditions` + `Events` + `Game`** — what the template uses. The manager is a plain node; needs are `WinCondition`s anywhere in the scene; the `Game` autoload owns the head release and the next scene. Sunset → restart. Most days will be this.
- **`WinConditionManager` + `DayManager`** — Sean's `platforming_day`. A day script *extends* `DayManager` and overrides `_on_condition_satisfied(key)` for per-need actions (drop a bridge). It loads its own `next_scene` (default: the reunion), so such a day must be **last** in `DAY_SCENES`. Fail shows `game_over.tscn`.

Which one survives is a team call (Saturday stand-up). Until then: new days on the template's system unless the day needs per-need actions, in which case copy `platforming_day` and put it last.

## 4. Checklist before you push

- [ ] `tools/smoke_test.sh` is ALL GREEN (or the one red line is your WIP plan)
- [ ] the day is in `Game.DAY_SCENES`
- [ ] both needs exist and can be met inside 30 s by a competent player
- [ ] instruction text is one line, or deliberately absent
- [ ] only palette colours, no generative art
- [ ] journal entry (`journals/<you>.md`)
