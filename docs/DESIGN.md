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
| **Words** | **No narrative text** by default. **Instruction text is on by default**; remove it wherever the design reads without it. |
| **Structure** | Intro → days → reunion. Intro and reunion are the **first two narrative beats** — define them first, but **don't build them first**. Intro: the head falls off and starts rolling down. |
| **A day** | **~30 seconds, one idea.** The head is **already stuck in place when the scene opens** — no roll-in *(revised Fri 18:45; see Player controls)*. The scene is flat ground / platforms; the body **solves both problems** (body need + mind need); the head is then released and **leaves the scene**, which ends the day. Days are **variations on a theme**, each with a WarioWare-style little setup beat. The implicit goal of every day: *get the head moving again* — what the snag is depends on the day. |
| **Day end / outro** | When every keyed win condition is met, **the head rolls off screen — and that roll *is* the day's outro beat.** There is **no separate outro cutscene scene**; the day only advances once the head is actually gone, so you always see it leave. Chain: `WinConditions` → `Events.day_completed` → `Game` calls `head.release()` → head travels + spins off screen → `head.left_scene` → `Game.next_day()`. *(Decided Fri 19:15, after two false starts the same evening: first the head owned a `release()` nobody triggered, then briefly the head was a scriptless prop with a separate outro scene. Landed here because the exit is identical in every day — so it belongs on the head, not copy-pasted per day — and because folding the outro into the day deletes a whole scene from the plan. TASKS.md C4 and the cut-order proposal were brought in line Sat 08:00.)* |
| **Needs** | One body need + one mind need per day. **The situation the head is in affects the body, and vice versa.** Needs *can* interact mechanically but don't have to. |
| **Timer & fail** | **The Sun is the day timer — it arcs across the top.** Fail: time runs out and **you can't get to the head** → restart that day. |
| **Scope** | **Max 5 minutes** of play. **Minimum shippable = 1 day.** Aiming for **~5 days.** |
| **Intrusive thoughts** | Abstracted as **kiki / bouba** shapes (spiky vs. round). |
| **Player controls** | The body. **The head is scripted, not simulated** — deterministic, identical every run. In a day scene it **starts already at its stuck position**; when both needs are met it is released and moves off screen, ending the day. *(Revised Fri 18:45, from "the head is a physics object (`RigidBody2D`) that rolls down an entry slope". Reasons: the snag position is authored anyway, T2's acceptance test demands "every run", `RigidBody2D` tuning is a flagged time sink — §4.3 — and entry/exit slopes were the most expensive part of the day template for the least gameplay. **Deferred, not cancelled:** a head-rolls-down-a-slope beat can be a separate interstitial scene between days, reusing the intro scene's pattern. **Reversible:** the head node stays a `RigidBody2D` held frozen, so real physics is a matter of not freezing it.)* |
| **Perspective** | 2D side-scroller. **Fixed camera per scene** — each day is one framed screen. |
| **Art** | Locked rule: **no generative art.** **Pixel art at 640×360** (confirmed — the project config stays). Palette: Gooseberry Ghost (8). **Body base: tbbk's CC0 32×32 skeleton** (opengameart.org/content/pixel-art-skeleton — "no credits needed"; credit anyway), recoloured to the palette and beheaded; **head: ours** (16×16). Tucker's own 16×32 body front is dropped. Tucker does art direction. |
| **Sound** | Tucker & Ben. Different music per day is the intent — "burn that bridge once we have some scenes". |
| **Stretch (from Friday)** | each day = a *mental* task + a *physical* task · the end scene is a **battle against the intrusive thoughts** |
| **(C2)** | **Bridge** (`platforming_day`). Head is already on the far ledge (the snag: a gap in the floor). Body need: three jumps up a stair of platforms to the high goal. Mind need: collect the goal on the far side. Twist: the high goal **drops a bridge** across the gap. Goals vanish when collected. ~30 s. File: `scenes/days/platforming_day.tscn` (Sean). |

### 2.2 How it's built

| | |
|---|---|
| **Days in code** | **One file per day.** Sean & Ben build the **scene template** first. **Friday's target: the template + one ~30-second day running end to end** (open → snag → two problems → head rolls out → next day), rectangles only — **met** (slopes were cut Fri 18:45, see Player controls; what exists: [CODEBASE.md](CODEBASE.md)). |
| **Win conditions** | **Keyed nodes** in the day scene (`body` / `mind`); the day completes when all keyed nodes are satisfied, which releases the head. **Their status is shown on the HUD to start** (remove later if it reads without). |
| **Day architecture** *(added 2026-08-21, smahr)* | **Signal up, call down.** `WinCondition` (leaf, on each goal) emits `satisfied(key)` → `WinConditionManager` (one per day) re-emits `condition_satisfied(key)` and `all_satisfied` → `DayManager` (base `class_name`, per-day subclass on a node) reacts: overrides `_on_condition_satisfied(key)` for day-specific actions (e.g. drop a bridge), and on `all_satisfied` releases the head → advances; `fail(reason)` shows game over. Day scene root is just a node holder. Files: `scenes/gameplay/win_condition.gd`, `win_condition_manager.gd`, `day_manager.gd`. **Note:** the `head_logic` branch has a parallel `WinConditions` (autoload-`Game`-based) version of this — leaf `WinCondition` names match; the manager/flow split must be reconciled at merge (see §3). *(Sat 08:00: both systems are now in the tree — `WinConditions`+`Events` for the template and day_panic, `WinConditionManager`+`DayManager` for platforming_day; which survives is **D13**; see [CODEBASE.md §5](CODEBASE.md).)* |
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
"You can't get to the head": the sun timer only? Does the body falling behind / off the fixed screen also fail? On fail: instant snap-back · short "try again" card · the head looks back at you. *(Blocks T3/T5 polish, not the template itself — default until decided: timer only, instant restart.)*
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
