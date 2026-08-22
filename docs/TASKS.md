# Tasks

Seed for the shared Google Doc (copy it over, or track here and tick boxes in PRs — your call). IDs match [task-dependencies.md](task-dependencies.md). Everything here traces to a decision in [DESIGN.md](DESIGN.md) §2; if a task needs something undecided, it says so.

**Deadline Sat 23:59 · submit by 22:30 · feature freeze 19:00. Tonight's target: T1–T8 + C2 — one ~30-second day running end to end with rectangles, exported to the web.**

Sizes: **S** ≤ 1 h · **M** 2–3 h · **L** half a day. "Done when" is the acceptance test — if you can't tick it, the task isn't done. Owner blank = unassigned; fill in at the Saturday stand-up at the latest. Node types in *italics* are the idiomatic Godot choice, not a requirement.

## Tonight (Fri) — template + one day

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **D5** | Decide fail details: sun timer only, or does falling behind/off-screen also fail? Instant restart or a card? (Default if undecided: timer only, instant restart.) | all | — | XS | written in DESIGN §2 |
| **E1** | Everyone: clone, open in Godot 4.7.1, run, download export templates (Editor → Manage Export Templates), get one tiny PR merged | all | — | S | three merged PRs on `main` |
| **T1** | Body controller — run, jump, slopes; rectangles. Tunables as `@export`. *CharacterBody2D + move_and_slide(), floor snap for slopes* | Sean / Ben | — | M | body runs up and down a slope and jumps, in the template scene |
| **T2** | Head — **starts already stuck** at its authored position; `release()` sends it off screen. Signals: `released`, `left_scene`. *RigidBody2D held `freeze`d and moved by script — scripted, not simulated (DESIGN §2.1)* **Scope cut Fri 18:45:** no roll-in, no entry/exit slopes, no `stuck` signal (it starts stuck). Slope roll-in is deferred to an optional interstitial scene. | Sean / Ben | D2 ✔ | S | head sits still at open; `release()` sends it off screen and emits `left_scene`, every run |
| **T3** | Sun timer — `@export day_length`, sprite arcs across the top, emits `sunset` → day fails → restart. *Node with a Tween or `_process` on a Path/arc* | Sean / Ben | D5 (default ok) | S | sun crosses the screen in `day_length` s and the day restarts at the end |
| **T4** | Keyed win-condition node — `WinCondition` with `@export key` (`body` / `mind`), `satisfy()`, `satisfied` signal; the day collects all of them and, when every key is satisfied, calls `Head.release()` | Sean / Ben | — | M | two dummy WinConditions satisfied in either order → head releases; one alone → nothing |
| **T5** | Day flow — `Game` autoload: ordered list of day scenes, `next_day()`, `restart_day()`, `go_to(i)` for testing; day advances when the head leaves the scene; after the last day → reunion scene (stub) | Sean / Ben | — | S–M | a stub day chains to itself twice and then to a "reunion" placeholder |
| **T6** | Fixed camera per scene — *Camera2D at scene centre, no follow* (one node in the template) | Sean / Ben | D3 ✔ | XS | scene is framed at 640×360 and doesn't move |
| **T7** | HUD — instruction text (`@export` per day) + win-key indicators that light up when satisfied (shown to start). *CanvasLayer + Labels/TextureRects* | Sean / Ben | T4 | S | satisfying a key flips its indicator; the day's instruction string shows |
| **T8** | **Day template scene** — flat ground / platforms · head placed at its stuck position · body spawn · Sun · HUD · WinConditions container · camera. *(Slopes cut Fri 18:45 — see T2.)* Plus a 5-line "how to make a new day" note in the scene/README (one file per day) | Sean / Ben | T1–T7 | M | a new day is one new file that runs end to end with no edits elsewhere |
| **C2** | **Day 1** — the minimum ship. Card locked in DESIGN §2.1 "Day 1 (C2)": three jumps to a high goal that drops a bridge over a gap to the far goal. File `platforming_day.tscn`, not the template. | Sean | T8 (can start on current template pieces) | M | 3 jumps → high goal vanishes + bridge drops → cross gap → far goal vanishes → head leaves, in the web build |
| **A0** | Art direction kickoff — palette, skeleton + head sprite sizes at 640×360, kiki/bouba sketch, what the sun looks like; say which placeholders get swapped first | Tucker | D6 ✔ | M | a one-screen style sheet in `assets/` everyone can see |
| **P1** | Restricted itch page with tonight's `web.zip` (`tools/export_web.sh`); secret URL in Discord | Tucker | E1 | S | a teammate opens the URL on their machine and the template runs |
| **E2** | Hard stop — agree the hour; commit + push before bed; `main` runs | all | — | — | everyone's home/asleep with nothing stuck on a branch |

## Saturday morning (09:00–13:00)

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **E3** | Stand-up ≤ 15 min: play last night's *web* build together; write the day cards (C1); one owner per day | all | P1 | S | cards exist, names next to days 2–5 |
| **C1** | Day cards ×~5 — one idea each (`name · snag / what befalls the head · body need · verb for each · twist · length`) | all | — | S | five cards in the doc |
| **C3a–d** | Days 2, 3, 4, 5 — one file, one owner each, built on the template; rectangles first, art after | one each | T8, C1 | M each | each day runs end to end in the web build |
| **C4** | Intro beat — head falls off and starts rolling down; leads into day 1. *AnimationPlayer cutscene over T1/T2, or a short playable* | ? | T1, T2, A1, A2 | M | from "Run" to day 1 without a hand on the keyboard (or with, if playable) |
| **A1** | Skeleton body + head sprites; swap into the template (budget an hour — bounds/pivots/collision will shift) | Tucker | A0 | M | template runs with sprites, feel unchanged |
| **A2** | Kiki / bouba intrusive-thought shapes (for the intro; mid-day use is §3.5) | Tucker | A0 | S | shapes in `assets/sprites/` |
| **S1** | SFX pass — jump, land, need satisfied, head released, day fail, sunset (jsfxr/ChipTone or hand-made) | Tucker / Ben | C2 | S–M | every event in day 1 makes a sound on web |

## Saturday afternoon (13:00–19:00)

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **E4** | 13:00 **scope check** — apply the cut order: Day 5 → Day 4 → Day 3 → intro becomes a text card → reunion becomes a text card → music | all | — | XS | the cut list is applied, not discussed |
| **C5** | Reunion beat — after the last day; head and body reunite (look: §3.6; brainstorm: faces camera, walks into the screen) | ? | C3 (at least the last day), A1 | M | last day → reunion → end card, in the web build |
| **A3** | Per-day props, sun, HUD art — swap behind stable code | Tucker | A1, C3 | M | no coloured rectangles left in shipped days (or deliberately kept) |
| **S2** | Per-day music — only if days exist and time allows | Tucker / Ben | C3 | M–L | each shipped day has a loop; web audio starts after first input |
| **P3** | Itch page — text, controls, 2 screenshots, a GIF, one line on the theme (17:00–19:00) | ? | A3 | S | page would be submittable as-is |
| **E5** | **Feature freeze 19:00** — nothing new after this, only fixes | all | — | — | last feature PR merged |

## Saturday evening (19:00–22:30) — ship

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **P2** | Export → itch; everyone plays every day on the *web* build in two browsers; showstoppers only | all | E5 | M | a list of zero open showstoppers |
| **P5** | Remove instruction text per day where it reads without it (keep it where it doesn't) | day owners | P2 | S | each day's text is a deliberate yes/no |
| **P4** | Final export, upload, page check, **Submit by 22:30** | ? (name them) | P2 | S | submission confirmed on the jam page, screenshot in Discord |

## Stretch — only after P2 has zero showstoppers

| ID | Task | Needs |
|---|---|---|
| **X1** | Each day = a *mental* task + a *physical* task | C3 |
| **X2** | End scene: battle against the intrusive thoughts | C5, A2 |
| **X3** | Intrusive thoughts as a mid-day hazard (§3.5) | A2, C3 |
| **X4** | Title / press-any-key screen (also unlocks web audio) | — |

## Cut order (agreed shape — confirm at 13:00)
Day 5 → Day 4 → Day 3 → intro cutscene becomes a text card → reunion becomes a text card → per-day music. **Never cut:** template, Day 1, a web build that runs, the itch page.
