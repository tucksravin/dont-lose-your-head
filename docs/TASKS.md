# Tasks

Seed for the shared Google Doc (copy it over, or track here and tick boxes in PRs — your call). IDs match [task-dependencies.md](task-dependencies.md); `E*` rows are clock events that live only here. Everything traces to a decision in [DESIGN.md](DESIGN.md) §2; where a row needs something undecided, it says so and is a decision row (`D*`).

**Deadline Sat 23:59 · submit by 22:30 · feature freeze 19:00.**
**Tonight's target:** T0–T8 + C2 — one ~30-second day running end to end with rectangles, on the web.
**Tonight's floor** (don't go to bed without it): E1 ×3 · body runs and jumps on a slope (T1) · head rolls in, stops, `release()` rolls it out (T2) · a `day_template.tscn` that instances both with the fixed camera, on `main` (T6/T8 skeleton) · that build on the itch URL (P1). T3/T5/C2 may slip to Sat 09:15 — fine.

Sizes: **XS** ≈ 15 min · **S** ≤ 1 h · **M** 2–3 h · **L** half a day. "Done when" is the acceptance test — if a teammate can't tick it, it isn't done. PRs cost ~10 min each including everyone's pull — batch merges roughly hourly; after pulling with Godot open, **Scene → Reload Saved Scene**. Owner blank = unassigned. Node types in *italics* are the idiomatic Godot choice, not a requirement.

\* = **proposed split so every scene file has exactly one owner** (DESIGN §4.3). Swap names freely; keep one name per file.

## Tonight (Fri) — template + one day

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **D5** | Decide fail details: sun timer only, or does falling behind / off the fixed screen also fail? Instant restart or a card? *(Default if undecided: timer only, instant restart.)* | all | — | XS | written in DESIGN §2 |
| **D11** | Decide: `R` = restart the day any time (softlock escape) · only on fail · unbound; `Esc`/`pause` = pause · nothing · drop it from the controls list (it also exits browser fullscreen); after the end card → intro · day 1 · "R to play again" | all | — | XS | written in DESIGN §2 |
| **J1** | Jam admin — re-read the jam page once: third-party-asset policy, AI/generative-art policy (ours: none — note the jam's exact wording), the submission form's required fields, credits rule, and the countdown's **deadline and timezone** vs our Sat 23:59. 5-line summary in Discord. Paste the Google Doc link into README → "Where things are" (or write "tracking in TASKS.md") | ? | — | XS | summary in Discord; exact time + timezone written beside the deadline in DESIGN §2 "Clock"; README link filled |
| **E1** | Everyone: clone, open in Godot 4.7.1, run, download export templates (Editor → Manage Export Templates), one tiny PR merged | all | — | S | three merged PRs, and each author has done the whole loop once: branch → push → PR → merge → `git pull` → Scene → Reload Saved Scene — and knows `git checkout -- <file>` for a `.tscn` Godot re-saved |
| **T0** ✔ | API contract — signal names in `scripts/autoload/events.gd` and the methods everyone codes against. Landed as `condition_satisfied` / `day_completed` / `day_failed` / `sunset`, `Head.release()`, `Game.next_day()` / `restart_day()` / `go_to()` | Sean + Ben | — | XS | ✔ `events.gd` on `main` declares them |
| **T1** ✔ | Body controller — run + jump on flat ground; tunables as `@export`. *`scenes/body/body.tscn`: CharacterBody2D + `move_and_slide()`* (slopes cut Fri 18:45 — see T2) | Ben | — | M | ✔ body runs and jumps in the template scene |
| **T2** ✔ | Head — **starts already stuck** at its authored position; `release()` sends it off screen (translate + spin, scripted). Signals: `released`, `left_scene`. Joins group `"head"` so `Game` can find it without a hard path. *`RigidBody2D` held `freeze`d (set in `head.tscn`) and moved by script — scripted, not simulated (DESIGN §2.1)* **Scope cut Fri 18:45:** no roll-in, no entry/exit slopes, no `stuck` signal (it starts stuck). **Fri 19:15:** that roll off screen *is* the day's outro beat — no separate outro scene. **Both ratified by the team Fri 20:09.** | Sean | D2 ✔ | S | ✔ head sits still at open; `release()` sends it off screen and emits `left_scene`, every run |
| **T3** ✔ | Sun timer — `@export day_length`, sprite arcs across the top, emits `sunset` → **day fails → restart**. *`scenes/sun/sun.tscn`, `_process` on a sine arc* | Sean / Ben | D5 (default ok) | S | ✔ every day reacts to sunset (Events days restart via `WinConditions` → `day_failed`; DayManager days show the game-over card) and a won day ignores it — `tools/smoke_test.sh day_sunset` proves both, per day |
| **T4** ✔ | Keyed win-condition node — `WinCondition` with `@export key` (`body` / `mind`), `satisfy()`, `satisfied` signal, plus a `WinConditions` manager that finds every condition in the day and emits `Events.day_completed` when the last one lands. `Game` calls `head.release()` off that signal, not this node | Ben | D7 ✔ | M | ✔ two WinConditions satisfied in either order → head releases; one alone → nothing |
| **T5** ✔ | Day flow — `Game` autoload is the scene manager: `DAY_SCENES`, `start_days()`, `next_day()`, `restart_day()`, `go_to(i)` for testing; listens to `Events.day_completed`, releases the head, advances once `head.left_scene` fires; after the last day → reunion. Sole owner of `change_scene_to_file()` | Sean | — | S–M | ✔ a stub day chains to itself twice, then reunion |
| **T6** ✔ | Fixed camera per scene — *Camera2D at scene centre, no follow* (one node in the template) | Ben | D3 ✔ | XS | ✔ scene is framed at 640×360 and doesn't move |
| **T7** | HUD — instruction text (`@export` per day) + win-key indicators that light up when satisfied (shown to start). *`CanvasLayer` + Labels/TextureRects; `Events.condition_satisfied` already fires* | ? (name someone) | T4 ✔ | S | satisfying a key flips its indicator; the day's instruction string shows |
| **T8** | **Day template scene** — `scenes/days/day_template.tscn`: flat ground / platforms · head at its stuck position · body spawn · Sun · HUD · WinConditions · camera. *(Slopes cut Fri 18:45 — see T2.)* Plus a 5-line "how to make a new day" note | Sean | T1–T7 | M | **most done** — missing the HUD (T7) and the note; a new day must be one new file that runs end to end with no edits elsewhere |
| **C2** | **Day 1** — the minimum ship. Step 1: **pick the day-1 card** (from [days/brainstorm.md](days/brainstorm.md) or the §3.7 needs list — a 5-minute call, whoever's around). Step 2: build it on the template as `day_01.tscn` and point `Game.DAY_SCENES` at it | ? | T8 | M | open → snag → both needs → head rolls out → next day, in the web build (`tools/export_web.sh` + the local http server it prints is enough; the itch upload is P1) |
| **A0** | Art direction kickoff — palette = Gooseberry Ghost (8) + bone shadow; body base = tbbk CC0 skeleton, recoloured, beheaded (decided); head = ours 16×16; sun = ours 16×16 (done); kiki/bouba sketch; which placeholders get swapped first. Tone: silly-spooky | Tucker | D6 ✔ | S | a one-screen style sheet in `assets/` everyone can see |
| **A1a** | Sprites into the scenes — body ✔ (PR #8), sun ✔ (PR #9); head sprite into `head.tscn`; palette pass on intro / reunion / day_template / goal rects | Tucker + scene owner | A0 | S | no default-coloured rectangles left in the template |
| **P1** | Restricted itch page with tonight's `web.zip` (`tools/export_web.sh`); secret URL in Discord | Tucker | E1 | S | a teammate opens the URL on their machine and the template runs, **and Sean and Ben are added as admins on the itch project and have export templates installed (E1) — so anyone can export + upload from here on** |
| **E2** | Hard stop — agree the hour. The last person to merge runs `tools/export_web.sh` and uploads; everyone pushes; `main` runs | all | P1 | — | nothing stranded on a branch; tonight's build is on itch |

## Saturday morning (09:00–13:00)

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **E3** | Stand-up ≤ 15 min: play last night's *web* build together; assign one owner per day; decide **D8** (cut order — proposal at the bottom of this file: react, reorder, or replace) | all | P1 | S | names next to days 2–3; D8 written in DESIGN §2 |
| **D8** | Decide the cut order — proposal at the bottom of this file; react, reorder, or replace. The day part should follow which days teach the most, so it may need C1 first | all | E3 | XS | written in DESIGN §2 |
| **D12** | Decide the jump arc. `body.gd` is `jump_velocity = -300` / `gravity = 980` → **max rise 45.9 px**, hang 0.61 s, horizontal reach 92 px. The platforming day's steps sit 36 px apart, so step 1 floats only 36 px over the ground and the 42-px-tall body clips through its railing when walking underneath. Raising it needs ≥ 47 px of jump. Options: (a) raise all three steps 12 px + `jump_velocity = -320` as a per-scene override on that day's Body, (b) same but change `body.gd` globally — consistent feel, but it retunes every day, (c) leave heights and fill step 1 down to the ground so there is nothing to walk under (no physics change). Deferred Fri 22:31; step art already ends on a post either way | all | — | XS | written in DESIGN §2, and the platforming day matches it |
| **C1** | Day cards ×~5 — one idea each (`name · snag / what befalls the head · body need · verb for each · twist · length`; ideas in [days/brainstorm.md](days/brainstorm.md)). Day 1's card is whatever C2 picked tonight — write it down too | all | — | S | cards in the doc |
| **C3a–b** | **Days 2 and 3** — one file, one owner each, on the template; rectangles first, art after | Sean\*, Ben\* | T8, C1 (C2 as the worked example) | M each | each day runs end to end in the web build |
| **C3c–d** | **Days 4 and 5** — start **only after Days 2–3 run in the web build** (expect ~13:00, not 11:00) | whoever's day ran first | C3a–b | M each | same |
| **C4** | Intro beat — head falls off and starts rolling down; leads into day 1. *AnimationPlayer cutscene over T1/T2, or a short playable.* Starts after Days 2–3 run, or becomes a text card (D8) | ? | T1, T2, A1, A2 | M | from "Run" to day 1 without (or with) a hand on the keyboard |
| **A1** | Body + head sprites: behead + crop the recoloured tbbk frames (`~/Desktop/skeleton_base.aseprite`, tags idle/throw/walk) → `assets/sprites/body_run_side.png` (4-frame strip) + `body_idle_front.png`; add the outline to `head.png` (+ roll frames). **Swap-in is done by the `body.tscn` / `head.tscn` owner in a 15-min pair with Tucker** — `Sprite2D` in place of the `ColorRect`, offset, pivot, collision shape | Tucker + scene owners | A0, T1/T2 stable | S–M | template runs with sprites, feel unchanged; kept rectangles listed in the PR |
| **A2** | Kiki / bouba intrusive-thought shapes (for the intro; mid-day use is §3.5 / X3) | Tucker | A0 | S | shapes in `assets/sprites/` |
| **S1** | SFX pass — jump, land, need satisfied, head released, day fail, sunset (jsfxr/ChipTone or hand-made). Tucker supplies, the day/template owner wires, after their day runs | Tucker / Ben | C2 | S–M | every event in day 1 makes a sound on web |
| **P1r** | Export + upload after every merged day and after the sprite swap — whoever merged (anyone can, per P1) | whoever merged | P1 | XS each | the itch URL always runs the latest `main` |

## Saturday afternoon (13:00–19:00)

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **E4** | 13:00 **scope check** — apply the cut order written in DESIGN §2 (D8); if it isn't written yet, the first 10 min of E4 is writing it | all | D8 | XS | §2 has a cut order and the tasks below reflect it — applied, not re-debated |
| **C5** | Reunion beat — after the last day; head and body reunite (look: §3.6; brainstorm: faces camera, walks into the screen). Or a text card (D8) | ? | C3 (at least the last day), A1 | M | last day → reunion → end card, in the web build |
| **A3** | Per-day props, sun, HUD art — swap behind stable code | Tucker | A1, C3 | M | no coloured rectangles left in shipped days (kept ones listed in the PR) |
| **S2** | Per-day music — only if days exist and time allows, after E4 | Tucker / Ben | C3, E4 | M–L | each shipped day has a loop; web audio starts after first input |
| **P2·0** | 17:00 mini-playtest of the current web build (round 0) → **P5 decisions land here, per day** | all | P1r | S | a list of what to fix before freeze |
| **P5** | Per day: remove instruction text and/or HUD win-lights where the day reads without them (keep them where it doesn't) | day owners | P2·0 | S | each day's text and lights are a deliberate yes/no |
| **P3** | Itch page — cover image (630×500), text, controls (keyboard; gamepad only if tested, §3.10), 2 screenshots, a GIF, one line on the theme, **credits** (Tucker / Sean / Ben; skeleton body base: tbbk — opengameart.org/content/pixel-art-skeleton, CC0; any third-party font, SFX or tool with its licence; answer any AI-disclosure field the jam has) — embed settings per README → "Exporting to itch.io". Text now; shots + GIF from the 19:00 build | ? | A3, J1 | S | a teammate opens the Restricted URL and ticks every item in this row; nothing from J1's summary is missing |
| **E5** | **Feature freeze 19:00** — nothing new after this, only fixes | all | — | — | last feature PR merged |

## Saturday evening (19:00–22:30) — ship

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **P2** | 19:00–21:30 Export → itch; everyone plays every day on the *web* build in two browsers (Chrome + Firefox; Safari if handy); **showstoppers only** = crash · softlock · can't progress · can't start on web · controls don't respond until a click (that one's expected — see README) | all | E5 | M | a written list of zero open showstoppers |
| **P4** | 21:30–22:30 Final export, upload, **itch page Restricted → Public**, page check, **Submit by 22:30** | ? (name them) | P2, J1 | S | submission confirmed on the jam page; opened from the jam's entries list in a private/incognito window (logged out — not via the secret URL) the game runs; screenshot in Discord |

## Stretch — only after P2 has zero showstoppers

| ID | Task | Needs |
|---|---|---|
| **X1** | Each day = a *mental* task + a *physical* task | C3 |
| **X2** | End scene: battle against the intrusive thoughts | C5, A2 |
| **X3** | Intrusive thoughts as a mid-day hazard (§3.5) | A2, C3 |
| **X4** | Title / press-any-key screen (also unlocks web audio) | — |

## Cut order — proposed, not decided (D8)
Nothing in DESIGN §2 ranks these yet (§4.5: *pick it while you're calm; write it in §2 once chosen*). Decide it at E3 once the day cards exist, before E4. **Proposal to react to:** Day 5 → Day 4 → Day 3 → intro cutscene becomes a text card → reunion becomes a text card → per-day music *(check "text card" against §2 Words: no narrative text — a title card with no prose still counts)*. **Never cut** (this part traces to §2 — min ship = 1 day, web target, template first): the template, Day 1, a web build that runs, the itch page.
