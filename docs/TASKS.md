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
| **T0** | 10-minute API contract before splitting T1–T7: signal names in `scripts/autoload/events.gd` (e.g. `sunset`, `need_satisfied(key)`, `day_completed`, `day_failed`, `head_left_scene`) and two method names everyone codes against: `Head.release()`, `Game.restart_day()` / `next_day()`. Land it as the first template PR | Sean + Ben | — | XS | `events.gd` on `main` declares the names; nobody invents a second one |
| **T1** | Body controller — run, jump, slopes; rectangles; tunables as `@export`. *`scenes/body/body.tscn`: CharacterBody2D + move_and_slide(), floor snap for slopes* | Ben\* | T0 | M | body runs up and down a slope and jumps, in the template scene |
| **T2** | Head — physics object: rolls down the entry slope, **stops at the snag**, `release()` lets it roll out the exit slope. Signals: `stuck`, `released`, `left_scene`. *`scenes/head/head.tscn`: RigidBody2D + CircleShape2D, PhysicsMaterial friction ≈ 1 / bounce 0, `can_sleep = false`; snag = a StaticBody2D blocker, or an Area2D at the snag that sets `freeze = true` — the freeze route is the fallback if the blocker jitters.* **Timebox 2 h**, then take the fallback | Sean\* | T0 | M–L | 10 of 10 runs (F6): rolls in, stops dead, `release()` rolls it out and `left_scene` fires |
| **T3** | Sun timer — `@export day_length`, sprite arcs across the top, emits `sunset` → day fails → restart. *`scenes/ui/sun.tscn`* | Sean\* | T0, D5 (default ok) | S | sun crosses the screen in `day_length` s and the day restarts at the end |
| **T4** | Keyed win-condition node — `WinCondition` with `@export key` (`body` / `mind`), `satisfy()`, `satisfied` signal; the day collects all of them and, when every key is satisfied, calls `Head.release()`. *`scenes/ui/win_condition.tscn`* | Ben\* | T0, D7 ✔ | M | two dummy WinConditions satisfied in either order → head releases; one alone → nothing |
| **T5** | Day flow — `Game` autoload: ordered list of day scenes (hard-coded array, or a scan of `scenes/days/` — owner's call; if you scan, use `ResourceLoader.list_directory()`, not `DirAccess`: the web export stores scenes as `.remap`), `next_day()`, `restart_day()`, `go_to(i)` for testing; advance when the head leaves the scene; after the last day → reunion scene (stub). Owns `game.gd`, `events.gd`, `project.godot` | Ben\* | T0 | S–M | a stub day chains to itself twice and then to a "reunion" placeholder |
| **T6** | Fixed camera per scene — *Camera2D at scene centre, no follow* (lives in the template) | Sean\* | — | XS | scene is framed at 640×360 and doesn't move |
| **T7** | HUD — instruction text (`@export` per day) + win-key indicators that light up when satisfied (shown to start). *`scenes/ui/hud.tscn`: CanvasLayer + Labels/TextureRects* | Ben\* | T4 | S | satisfying a key flips its indicator; the day's instruction string shows |
| **T8** | **Day template scene** — `scenes/days/day_template.tscn`: entry slope · flat middle · exit slope · head spawn · body spawn · Sun · HUD · WinConditions container · camera. Plus a 5-line "how to make a new day" note in the scene (or README) | Sean\* | T1–T7 | M | copy the template to `day_xx.tscn`, register it with `Game` if T5 keeps a list (one line) — it runs end to end and nothing else changes; the note says exactly those steps |
| **C2** | **Day 1** — the minimum ship. Step 1: **pick the day-1 card tonight** (from [days/brainstorm.md](days/brainstorm.md) or the §3.7 needs list — a 5-minute call, whoever's around). Step 2: build it on the template | ? | T8 | M | slope in → snag → both needs → head rolls out → next day, in the web build (`tools/export_web.sh` + the local http server it prints is enough; the itch upload is P1) |
| **A0** | Art direction kickoff — palette, skeleton + head sprite sizes at 640×360, kiki/bouba sketch, what the sun looks like; which placeholders get swapped first. Tone: silly-spooky | Tucker | D6 ✔ | M | a one-screen style sheet in `assets/` everyone can see |
| **P1** | Restricted itch page with tonight's `web.zip` (`tools/export_web.sh`); secret URL in Discord | Tucker | E1 | S | a teammate opens the URL on their machine and the template runs, **and Sean and Ben are added as admins on the itch project and have export templates installed (E1) — so anyone can export + upload from here on** |
| **E2** | Hard stop — agree the hour. The last person to merge runs `tools/export_web.sh` and uploads; everyone pushes; `main` runs | all | P1 | — | nothing stranded on a branch; tonight's build is on itch |

## Saturday morning (09:00–13:00)

| ID | Task | Owner | Needs | Size | Done when |
|---|---|---|---|---|---|
| **E3** | Stand-up ≤ 15 min: play last night's *web* build together; assign one owner per day; decide **D8** (cut order — proposal at the bottom of this file: react, reorder, or replace) | all | P1 | S | names next to days 2–3; D8 written in DESIGN §2 |
| **D8** | Decide the cut order — proposal at the bottom of this file; react, reorder, or replace. The day part should follow which days teach the most, so it may need C1 first | all | E3 | XS | written in DESIGN §2 |
| **C1** | Day cards ×~5 — one idea each (`name · snag / what befalls the head · body need · verb for each · twist · length`; ideas in [days/brainstorm.md](days/brainstorm.md)). Day 1's card is whatever C2 picked tonight — write it down too | all | — | S | cards in the doc |
| **C3a–b** | **Days 2 and 3** — one file, one owner each, on the template; rectangles first, art after | Sean\*, Ben\* | T8, C1 (C2 as the worked example) | M each | each day runs end to end in the web build |
| **C3c–d** | **Days 4 and 5** — start **only after Days 2–3 run in the web build** (expect ~13:00, not 11:00) | whoever's day ran first | C3a–b | M each | same |
| **C4** | Intro beat — head falls off and starts rolling down; leads into day 1. *AnimationPlayer cutscene over T1/T2, or a short playable.* Starts after Days 2–3 run, or becomes a text card (D8) | ? | T1, T2, A1, A2 | M | from "Run" to day 1 without (or with) a hand on the keyboard |
| **A1** | Skeleton body + head sprites (Tucker draws). **Swap-in is done by the `body.tscn` / `head.tscn` owner in a 15-min pair with Tucker** — `Sprite2D` in place of the `ColorRect`, offset, pivot, collision shape. Budget the hour for the swap on top of drawing time | Tucker + scene owners | A0, T1/T2 stable | M | template runs with sprites, feel unchanged; kept rectangles listed in the PR |
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
| **P3** | Itch page — cover image (630×500), text, controls (keyboard; gamepad only if tested, §3.10), 2 screenshots, a GIF, one line on the theme, **credits** (Tucker / Sean / Ben + any third-party font, SFX or tool with its licence; answer any AI-disclosure field the jam has) — embed settings per README → "Exporting to itch.io". Text now; shots + GIF from the 19:00 build | ? | A3, J1 | S | a teammate opens the Restricted URL and ticks every item in this row; nothing from J1's summary is missing |
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
