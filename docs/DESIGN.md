# Don't Lose Your Head — Design Doc

*Game jam · theme **Body and Mind** · Godot 4.7.1 · Tucker, Sean, Ben*

> ~8 minute read. **§1–2 are settled** — §2 now includes Friday's meeting ([meeting-notes-friday.md](../meeting-notes-friday.md) is the source; if this doc and the notes disagree, the notes win and this doc is wrong — except where §2 records a later decision made in chat; so far only the deadline, §2.3 Clock). **§3 is what's still open.** §4–6: how we run the weekend. **Task list: [TASKS.md](TASKS.md)** (seed for the Google Doc) · dependencies: [task-dependencies.md](task-dependencies.md).

---

## 1. Pitch & thesis

A skeleton is assaulted by intrusive thoughts and its head pops off. For the rest of the game the head and body are separate. Each scene is a **day**: the **Sun** is the timer, something befalls the **head**, and the **body** chases after it. Both have to be taken care of before the day can end. At the end, they're reunited.

**Thesis (verbatim):**

> *The mind and the body have different needs, but also taking care of the mind is taking care of the body (and vice versa).*

Use it as the test for every idea this weekend: *does this make the player feel that?*

---

## 2. Locked — what we've agreed

### 2.1 The game

| | |
|---|---|
| **Title** | Don't Lose Your Head |
| **Tone** | **Silly-spooky** (Undertale as a reference). The character is a **skeleton**. |
| **Words** | **No narrative text** by default. **Instruction text is hidden** *(smahr Sat 19:19)* — every day's `Instruction` Label stays in the scene but is off (`DayManager._hide_help()`; transition HUD too). |
| **Structure** | Intro → days → reunion. Intro and reunion are the **first two narrative beats** — define them first, but **don't build them first**. Intro: the head falls off and starts rolling down. |
| **A day** | **~30 seconds, one idea.** The head is **already stuck in place when the scene opens** — no roll-in *(revised Fri 18:45; see Player controls)*. The scene is flat ground / platforms; the body **solves both problems** (body need + mind need); the head is then released and **leaves the scene**, which ends the day. Days are **variations on a theme**, each with a WarioWare-style little setup beat. The implicit goal of every day: *get the head moving again* — what the snag is depends on the day. |
| **Day end / outro** | When every keyed win condition is met, **the head rolls off screen — and that roll *is* the day's outro beat.** There is **no separate outro cutscene scene**; the day only advances once the head is actually gone, so you always see it leave. Chain: `WinCondition` → `WinConditionManager` → **`DayManager`** calls `head.release()` → head travels + spins off screen → `head.left_scene` → **`Game.next_day()`** (the playlist). *(Revised Sat 10:32: DayManager owns *when* a day ends; Game owns *which file is next*. Previously `WinConditions` → `Events.day_completed` → Game released the head, and DayManager days named their own `next_scene` — that forced them last in the run. D13 locked to this.)* |
| **Transitions** | Between days, an optional interstitial: **the head rolls away down one long slope, the player runs the body after it, and where the head stops it lands in its next predicament** (`scenes/transition/transition.tscn`). **Decided Sat 08:40 (Tucker): the ground is one straight slope, and the body stays under the player's control** — the head is scripted (a `PathFollow2D` + `Tween`, identical every run, ~2.2 s), the situation plays when the body gets close (or after 2.5 s), and the beat ends only once the body has reached the head (no timeout — a hint label says to go after it), then a fade and `Game.next_day()`. Transitions sit in `Game.DAY_SCENES` right before the day they lead into. **Forking rule (decided Fri 22:50, Tucker): one inherited scene per situation** — `Scene → New Inherited Scene` from `transition.tscn`, a script that `extends` `transition.gd` and overrides only `_play_arrival()`, plus any props the beat needs. `transition_cage.tscn` (head gets caged → `day_panic`) is the worked example. Alternatives considered: one shared scene with an `@export` arrival slot (recommended by the agent: per-day work is one tiny scene, no inherited-.tscn merge pain), or duplicate-and-edit. Inherited scenes chosen for being real scenes you can open and tweak; the cost is opaque `.tscn` diffs, so keep base-scene edits rare and announced. This is the "head-rolls-down-a-slope beat" that Player controls (below) deferred on Friday. **Sat afternoon (Tucker): still one slope, but the head starts at rest at the top and the situation is what sends it rolling — it is not running away from the body; the body has almost caught up (the "I almost caught up to you" moment, `trigger_distance`) when the day's event happens to the head (the cage drops on it), and the knock rolls it off down the slope; the beat still ends when the body reaches it. The caged head rolls all the way off the screen (Tucker, Sat), so there the body follows it off and the fade happens off screen.** *(Replaces a two-slope/shelf sketch from earlier Saturday that never merged.)* The intro got the same spirit: no scripting moves the body, the scene ends when the player runs off, and it has the Sun timer (sunset restarts it). |
| **Needs** | One body need + one mind need per day. **The situation the head is in affects the body, and vice versa.** Needs *can* interact mechanically but don't have to. |
| **Timer & fail** | **The Sun is the day timer — it arcs across the top.** Fail: time runs out (or pit / panic / …) → **game-over card + Retry** (`scenes/ui/game_over.tscn`). Instant reload without the card is gone. *(D5 locked Sat 10:32, smahr.)* |
| **Scope** | **Max 5 minutes** of play. **Minimum shippable = 1 day.** Aiming for **~5 days.** |
| **Intrusive thoughts** | Abstracted as **kiki / bouba** shapes (spiky vs. round). **Head thought stream** *(smahr Sat 17:38; intro/transition Sat 17:48):* the head always emits a **small visual-only** stream of lil kikis that rise and fade (`scenes/head/head_thoughts.tscn`). On `head.tscn` for days; instanced on the intro blob and the transition sprite (`follow` tracks the path head). Separate from per-day hazards (rain, flying kikis, swarm, bounce, cloud). |
| **Player controls** | The body. **The head is scripted, not simulated** — deterministic, identical every run. In a day scene it **starts already at its stuck position**; when both needs are met it is released and moves off screen, ending the day. *(Revised Fri 18:45, from "the head is a physics object (`RigidBody2D`) that rolls down an entry slope". Reasons: the snag position is authored anyway, T2's acceptance test demands "every run", `RigidBody2D` tuning is a flagged time sink — §4.3 — and entry/exit slopes were the most expensive part of the day template for the least gameplay. **Deferred, not cancelled:** a head-rolls-down-a-slope beat can be a separate interstitial scene between days, reusing the intro scene's pattern. **Built Fri night, playable Sat 08:40 — see the Transitions row above.** **Reversible:** the head node stays a `RigidBody2D` held frozen, so real physics is a matter of not freezing it.)* |
| **Perspective** | 2D side-scroller. **Fixed camera per scene** — each day is one framed screen. **Left edge is a wall** *(smahr Sat 19:26)* — the body cannot walk off-screen and get stuck (`WorldBoundaryShape2D` at x=0, from `body.gd`; transition already has `WallLeft`). The right edge stays open so the head can leave. |
| **Art** | Locked rule: **no generative art.** **Pixel art at 640×360** (confirmed — the project config stays). Palette: Gooseberry Ghost (8). **Body base: tbbk's CC0 32×32 skeleton** (opengameart.org/content/pixel-art-skeleton — "no credits needed"; credit anyway), recoloured to the palette and beheaded; **head: ours** (16×16). Tucker's own 16×32 body front is dropped. Tucker does art direction. |
| **Sound** | Tucker & Ben. Different music per day is the intent — "burn that bridge once we have some scenes". |
| **Stretch (from Friday)** | each day = a *mental* task + a *physical* task · the end scene is a **battle against the intrusive thoughts** |
| **(C2)** | **Bridge** (`platforming_day`, rework smahr Sat 15:56). Head sits on an unreachable centre perch. Right half is a **spike pit**. A drawbridge starts **up**. Platforms of mixed sizes plus one **moving rider** lead to a kiki floating over a button in the pit; **stomp the kiki** and it **falls onto the button** (spikes fail). That drops the bridge; the perch **tilts** and dumps the head onto it. File: `scenes/days/platforming_day.tscn`. |
| **Lockdown** *(C3b, smahr Sat 11:02; wrong-pad rain Sat 16:51; from-head Sat 18:02)* | WarioWare split attention. Setup beat: head waits alone in the middle; walk to it picks it up, a vertical bar blocks the right exit, a pedestal opens on the right; stand on the pedestal seats the head. Then the puzzle: dodge a rain of thoughts (hit → game-over card) while answering 4 math pads with **interact** (E). Thoughts **rise off the seated head** then rain from the top (interval / speed / miss_mult unchanged). **Wrong pad does not fail** — it **speeds the rain**. A hit → card. Last correct answer **tips the pedestal toward the exit** and the head rolls off. File: `scenes/days/day_lockdown.tscn`. |
| **Working Out** *(C3c, smahr Sat 12:01; barbell art Sat 18:32)* | Button masher. Loose head on the right, kikis swarm it (`kiki_frames.tres`) and **block the walk to the head**. Body walks into the barbell (`barbell_frames.tres`: `alone` → `with_body`), then mashes `jump` (Space) — `lifting` plays — to push the swarm out. Kikis **creep back**. Fail: **sunset** or **kikis touching the head**. Swarm gone satisfies body + mind; head releases. File: `scenes/days/day_workout.tscn`. |
| **Don't Panic (still)** *(smahr Sat 15:18; uncaged Sat 17:30)* | Head **stuck in a tree** on the right-edge cliff — **not caged** (the cage drops in `transition_cage`). Moving winds **panic**; stand still until it hits **0**. Then the head **sighs and falls backward** out of the canopy and off the drop. Fail at max or walking off the cliff. Kiki cloud closes in as panic rises. File: `scenes/days/day_panic_still.tscn`. |
| **Don't Panic (cage)** *(rework, smahr Sat 14:50 — thoughts.md)* | Head hangs in a cage in the air. Moving winds **panic** (fail at max). Flying kikis to jump (hit = fail). Stand on the floor button and `interact` to open it — that satisfies **body + mind**. Same kiki cloud as the still day. File: `scenes/days/day_panic.tscn`. Slot: still → cage transition → this → glasses transition. |
| **(Velma)** *(rework smahr Sat 17:01; blur Sat 17:08; spawn left Sat 17:11)* | **Velma** (`day_velma`). Body starts on the **left**. Head sits on a **high right perch**. Glasses sit on a **centre platform**. Climb starts on the right and leads left to the glasses. A **small clear circle** sits on the body **and** the head from the start; the room stays blurred. Pickup = **body** (blur stays; **body locks** so it cannot walk off). Throw hits the head = **mind**, **then** the screen unblurs, skull knocked off the perch, rolls out. File: `scenes/days/day_velma.tscn`. |
| **Mirror World** *(C3d, smahr Sat 13:49; from-head Sat 18:02)* | Head on a right-hand platform, staring into a tall glass from floor to skull. It **alternates** look-at-glass (walk *and* jump flipped: ↓ hops) and look-at-player (normal). Kikis **leave the head**, curve right, drop, then fly left at the body — jump them; a hit is the game-over card. Walk to the glass, `interact` throws it off the right; the head rolls after it. Fail: **sunset** or **kiki**. File: `scenes/days/day_mirror.tscn`. **No use key (Sat, Tucker): getting the body within `grab_radius` of the glass throws the head — no flipped-jump throw any more.** |
| **Reunion** *(C5, smahr Sat 14:08)* | Walk in with the **camera upside down** (`zoom.y = -1`). Dive onto the skull (the animation we already had), bounce to standing as the screen rights itself, walk off into a parked sun. File: `scenes/reunion/reunion.tscn`. End card after the fade is still N1 (`main.tscn`). |

### 2.2 How it's built

| | |
|---|---|
| **Days in code** | **One file per day.** Sean & Ben build the **scene template** first. **Friday's target: the template + one ~30-second day running end to end** (open → snag → two problems → head rolls out → next day), rectangles only — **met** (slopes were cut Fri 18:45, see Player controls; what exists: [CODEBASE.md](CODEBASE.md)). |
| **Win conditions** | **Keyed nodes** in the day scene (`body` / `mind`); the day completes when all keyed nodes are satisfied, which releases the head. **Their status is shown on the HUD to start** (remove later if it reads without). |
| **Day architecture** *(locked Sat 10:32, smahr — D13)* | **Signal up, call down.** `WinCondition` (leaf) emits `satisfied(key)` → `WinConditionManager` (one per day; also mirrors `Events.condition_satisfied` for HUD/Sfx) → **`DayManager`** (base `class_name`; per-day subclass only when the day needs a hook). DayManager owns **when** the day ends: on `all_satisfied` it releases the head then calls `Game.next_day()`; on `fail(reason)` it shows the game-over card. **`Game` is the playlist only** (`DAY_SCENES`, `start_days()`, `go_to()`, `change_scene()`). Days can sit anywhere in the list. Files: `scenes/gameplay/win_condition.gd`, `win_condition_manager.gd`, `day_manager.gd`, `scenes/ui/game_over.tscn`. The old `WinConditions` + `Game._on_day_completed` path is deleted. |
| **Engine / target** | Godot 4.7.1 → itch.io web (HTML5), manual export. |

### 2.3 How we work

| | |
|---|---|
| **Git** | **Pull requests** into `main`. **Anyone can merge someone else's PR; self-merge if necessary** (don't wait at 01:00). One owner per `.tscn` still applies — PRs don't merge scene files for you. |
| **Tasks** | Shared **Google Doc** — *(paste the link into README → "Where things are")*. Dependencies: [task-dependencies.md](task-dependencies.md). |
| **Roles to start** | Art direction: **Tucker** · Scene template: **Sean, Ben** · Sound: **Tucker, Ben** |
| **Clock** | Jam started **Fri 10:00**. **Deadline: Saturday at midnight (Sat 23:59)** — per Tucker, overriding the notes' "Sunday night". From Fri ~17:30 that's ~30 h on the clock, ~21 working hours each after tonight's sleep. **Submit by ~22:30 Sat.** |

---

## 3. Still open

### Answer now
#### 3.1 Fail details
**Presentation locked (D5):** game-over card + Retry. Still open: the sun timer only, or does the body falling behind / off the fixed screen also fail? Flavour on the card (head looks back at you) vs the generic overlay.
#### 3.2 Google Doc link
Paste it into README → "Where things are".

### Decide when you build it
#### 3.3 Needs interaction, per day — allowed, not required; decide per day card.
#### 3.4 Day timer numbers — seconds allowed vs the ~30-second design; same every day?
#### 3.5 Intrusive thoughts mid-day — intro only · recurring hazard (kiki shapes).
#### 3.6 Intro & reunion specifics — title / "press any key" screen (also unlocks web audio): yes · no. Skip the intro on retry? Reunion trigger and look (brainstorm: *the head faces the camera and the guy walks into the screen*). Stretch: the final battle.
#### 3.7 Day card — ideas are collecting in [days/brainstorm.md](days/brainstorm.md). A five-line format for pitching one, if you want it: `name · the snag / what befalls the head (mind need) · the body need · the verb for each · the twist · length`. Needs from the brainstorm: hungry · hurt · tired · cold · can't see · only hears · falls in love · scared · lonely.
#### 3.8 Mental vs. physical task (stretch) — what distinguishes them, mechanically?
#### 3.9 Kiki / bouba mapping *(art direction)* — which is which?
#### 3.10 Controller & browsers — gamepad is mapped: test it · ignore it. Browser matrix: Chrome · + Firefox · + Safari. `pause` = Esc also exits browser fullscreen — keep or remap?
#### 3.11 Team habits — sync cadence · tiebreak when time's up · stuck rule · outside playtesters via the itch secret URL · commit + push before stepping away.
#### 3.12 Jam admin — re-read the rules (third-party assets, generative art); itch page as **Restricted** tonight; what "submittable" means (runs from the itch URL in two browsers · no softlock · controls shown); who presses Submit.

#### 3.13 Idea bank (appendix, from brainstorm.md — steal freely)
- WarioWare with two things going on at once
- "What happens to the head will also happen to the body"
- Only the head can see what's going on · minigames seen from the head's perspective
- Bullet hell: head attacks only work on head enemies, body attacks only on body enemies
- Head solves puzzles, body runs/dodges/fights — could they switch roles?
- Stances: zen & in tune vs. berserker & separated — or a spectrum (distance = speed/chaos/fragility)
- Controls orientation changes with the head's orientation
- The head falls in love · the body falls in love
- What if the head can't see? · only hears? · the body is hurt? · hungry?
- Totally 2D, then the head faces the camera and the guy walks into the screen

---

## 4. Making a first jam succeed

Honest advice, in priority order.

1. **Template + one day = the vertical slice.** Friday's call: scene template first, minimum ship is one day. So the first milestone is one ~30-second day running end to end — open → snag → two problems → head rolls out → next day — with coloured rectangles. Every day after is an insert; intro and reunion slot in around it.
2. **Export to the web tonight, then every few hours.** Web is where jam builds die (renderer, audio, threads, load time). The pipeline is proven on Tucker's machine — `tools/export_web.sh` → upload to a **Restricted** itch page (secret URL; *Draft* is owner-only) tonight so Saturday night has zero surprises. On web, `print()` goes to the browser devtools console, and keys only arrive once the canvas has focus (click it first). Keep the last known-good `web.zip` in Discord.
3. **One owner per scene file.** `.tscn` merges are the worst part of Godot-in-a-team. Say "I'm in `day_02.tscn`" in Discord before you open it. Scripts merge fine. `project.godot` (input map, autoloads) and `export_presets.cfg` are shared files too — give them an owner. After `git pull` with the editor open: **Scene → Reload Saved Scene**, or restart Godot. If Godot re-saves a `.tscn` you didn't touch, `git checkout -- <file>` before committing. First-timer time sinks to timebox at ~45 min: TileMap/TileSet editor, AnimationTree, shaders, `RigidBody2D` tuning.
4. **Small PRs, short-lived branches.** You chose PRs — keep them hours long, not days: a `.tscn` that lives on a branch overnight is a conflict in the morning. Merge rules are decided (§2.3: anyone merges, self-merge if necessary) — so nobody waits at 01:00.
5. **Pick the cut order while you're calm.** Days beyond the first are the cut list, in reverse order of how much each one teaches. Write it in §2 once chosen.
6. **Timebox tasks to ~2 h.** If it's not done, ship what works or cut it. Polishing one thing for 5 hours is how jams are lost.
7. **Placeholder art until the mechanic it's for is stable.** Code stabilises against rectangles; art swaps in behind stable code. Swapping `ColorRect` → `Sprite2D` changes bounds, pivots, and collision feel — budget an hour for it, body and head first.
8. **Sleep tonight.** Saturday is one long day with the deadline at its end — agree a hard stop tonight and keep it.
9. **Feature-freeze Saturday ~19:00; submit by ~22:30.** Uploads fail, the clock is cruel, itch is slow at deadline. The last three hours = playtest the *web build* in two browsers, fix showstoppers, export, page, submit.
10. **The itch page is part of the game.** GIF/screenshot, controls, one line on how it hits the theme. Judges read it before they play.

**Godot, for people who already program:** the ten-line mental model and a glossary are in README → *Godot in ten lines*. "Your first 2D game" in the official docs is a 1-hour read that covers 80 % of what we need: https://docs.godotengine.org/en/stable/getting_started/first_2d_game/

---

## 5. Schedule

Deadline **Sat 23:59**. Tonight = template + one day. Saturday = days, beats, art, sound, ship. Details per task in [TASKS.md](TASKS.md).

| When | Goal |
|---|---|
| **Fri 17:30–19:00** | Everyone: clone, run, download export templates, one PR merged. Sean & Ben start the template; Tucker: art direction kickoff + Restricted itch page with tonight's `web.zip`. |
| **Fri 19:00–late** | **Template + one ~30-second day end to end**, rectangles (tonight's target). Web export before bed. **Hard stop — agree the hour.** |
| **Sat 09:00** | Stand-up (≤15 min): play last night's *web* build together; write the day cards; assign one owner per day. |
| **Sat 09:15–13:00** | Finish anything that slipped from tonight first. Then **Days 2 and 3** (one file, one owner each); Tucker: sprite swap-in with the scene owners (A1) + kiki/bouba (A2). SFX once Day 1 is on the web. Days 4–5 and the intro start **only after Days 2–3 run in the web build**. Export after every merged day. |
| **Sat 13:00–14:00** | Lunch + **scope check** — apply the cut order now, not at 21:00. |
| **Sat 14:00–17:00** | Finish days. Reunion beat. Per-day props/sun/HUD art. Music only after the scope check and only if days 1–3 run. |
| **Sat 17:00–19:00** | Mini-playtest of the 17:00 web build → **instruction-text / HUD-light decisions land here, per day**. Itch page text, controls, credits written now; screenshots + GIF from the 19:00 build. Last features. **Feature freeze 19:00.** |
| **Sat 19:00–21:30** | Export → itch. Everyone plays every day on the web build in two browsers. Showstoppers only. |
| **Sat 21:30–22:30** | Final export, upload, itch **Restricted → Public**, logged-out check from the jam's entries list, **Submit by 22:30.** |
| **Sat 23:59** | Deadline. |

---

## 6. Roles

| Area | Owner | Notes |
|---|---|---|
| Art direction | **Tucker** | pixel 640×360; palette, skeleton + head, kiki/bouba shapes, sun, HUD |
| Scene template | **Sean, Ben** | body controller, scripted head release (§2.1), sun timer, keyed win nodes, day flow, fixed camera, instruction HUD — TASKS.md T1–T8 |
| Sound | **Tucker, Ben** | SFX, per-day music — once scenes exist |
| Day authoring | | one owner per day file |
| Intro & reunion | | first two narrative beats; built after the template + a day |
| Export, itch page, playtest, jam admin | | `tools/export_web.sh` runs, the itch page, rules check (§3.12), presses Submit |
| Shared config | | `project.godot` (input map, autoloads) and `export_presets.cfg` — one owner; others ask first |

---

## 7. Conventions

See [README.md](../README.md) — folders, naming, input actions, export steps, git rules. Short version: input via actions, not keys; tunables as `@export`; scripts next to their scenes; commit `.import`/`.uid`, never `.godot/` or `build/`; one owner per `.tscn`; PRs into `main`.

*Sources: [meeting-notes-friday.md](../meeting-notes-friday.md) · [brainstorm.md](../brainstorm.md). LLM working agreement: [CLAUDE.md](../CLAUDE.md). LLM activity logs: [journals/](../journals/) (one per person; `claudeWorkJournal.md` is the frozen Friday log).*
