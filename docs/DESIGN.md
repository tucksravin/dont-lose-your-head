# Don't Lose Your Head — Design Doc

*Game jam · theme **Body and Mind** · Godot 4.7.1 · clock: Fri 2026-08-21 10:00 → **Sun 10:00** · Tucker, Globi, hugububba*

> ~10 minute read. §1–2 are settled. §3 is **tonight's agenda** — open questions with options, none pre-chosen. §4–6 are how we'll run the weekend. Add decisions to §2 as you make them; this doc is the source of truth for "what are we building".

---

## 1. Pitch & thesis

A skeleton is assaulted by intrusive thoughts and its head pops off. For the rest of the game the head and body are separate. Each scene is a **day**: the **Sun** is the timer, something befalls the **head**, and the **body** chases after it. Both have to be taken care of before the day can end. At the end, they're reunited.

**Thesis (verbatim):**

> *The mind and the body have different needs, but also taking care of the mind is taking care of the body (and vice versa).*

Use it as the test for every idea this weekend: *does this make the player feel that?*

---

## 2. Locked — what we've agreed

| | |
|---|---|
| **Title** | Don't Lose Your Head |
| **Structure** | Intro (head pops off) → N days → Reunion |
| **A day** | Sun rises → something befalls the head, body chases it → a **body need** *and* a **mind need** must both be satisfied before sunset → next day |
| **Fail** | Sunset with either need unmet, *or* body lost off-screen → **restart that day** (the exact lose distance is tuning — §3.9) |
| **Player controls** | The **body**. The **head** is on rails — a scripted path per day |
| **Perspective** | 2D side-scroller; **camera follows the head** |
| **Art** | Locked rule: **no generative art**. Style is open (§3.14). The project is *provisionally* configured for pixel art at 640×360; switching to HD is a few Project Settings (README says how) |
| **Engine / target** | Godot 4.7.1 → itch.io web (HTML5), manual export |
| **Build order** | **Intro and reunion first**, then days slot in as ideas come. Friday-night target: intro → a stub day → reunion running end to end |
| **Reunion trigger** | Body walks to head; press `interact` when within range → body snaps to head (Tween) → fade to black → next scene |
| **Time** | 48-hour jam, started **Fri 10:00** → deadline **Sun 10:00**. Team starts ~Fri 16:00 *(assumed — confirm)* → ~42 h on the clock; after two nights' sleep that's roughly **24–26 working hours each**. Sunday morning is for submitting, not building |

Everything not in this table is open. When you decide something in §3, move it here.

---

## 3. Decide together — tonight's agenda

Options are candidates, not recommendations. Godot terms used below are explained in README → *Godot in ten lines*.

Suggested split: **A. Game** ~30 min · **B. Code** ~10 min · **C. Team & admin** ~15 min (run 3.17 in parallel while you talk). That's ~2.5 min per item — so a *suggestion*, not a cut: decide tonight what blocks tonight's build (**3.1–3.4**, the *platforming?* line of 3.6, **3.11**, **3.14**, **3.16–3.17**) and mark the rest **"decide when you build it"**. Anything you can't settle: pick the cheapest option, move on, revisit Saturday. Move decisions into §2 as you make them.

### A. Game

#### 3.1 Tone & the character
- One sentence of tone so art, sound, and any text agree: silly-spooky? gentle and melancholy? slapstick? How heavy do "intrusive thoughts" get?
- Who is this? The brainstorm pictured a **skeleton** (the joke works, the art is easy). Confirm or change.
- Any words on screen at all (day titles, one line per day), or wordless?

#### 3.2 Intro & reunion — you're building these first
- **Intro:** playable (you walk, thoughts swarm, head pops) · short non-interactive cutscene · a title card. Is the intro also the tutorial (move, jump, interact)? What do intrusive thoughts look like — creatures, scribbles, words? How does the head leave — pops, rolls, flies?
- **Title / "press any key" screen:** yes · no. (Browsers block audio until the first input either way — README gotchas.)
- **On retry or browser refresh:** always from the intro · skip straight to the day · remember the furthest day in `user://` (works on web). Moot if the intro is under ~20 s.
- **Reunion:** what triggers it (walk up and `interact`? automatic on proximity?) and what it looks like — brainstorm: *the head ends up facing camera and the guy walks into the screen.* How long? Credits?
- What does intro + reunion with **zero days** between them feel like — is that already a tiny complete game? (That's the Friday-night target.)

#### 3.3 What a day is — the "day card"
Days get filled in as ideas come, so agree the **card** for pitching one (five lines, anyone can write one):
`name · what befalls the head (mind need) · what the body needs (body need) · the verb for each — how the player actually satisfies it · the twist, if any · rough length`
- Body needs (brainstorm): hungry · hurt · tired · cold · …
- Mind needs (brainstorm): can't see · can only hear · falls in love · scared · lonely · …
- Verbs: touch a pickup · stay near the head for T seconds · carry a thing to the head · stand on a switch at a fork · a WarioWare-style micro-task · …
- Is the need an **obstacle** (head can't see → it stalls at forks until the body points it), an **objective** (bring it glasses), or both?
- Is `interact` needed at all, or is everything touch/proximity? (It's mapped either way.)

#### 3.4 How many days, how long a run, how hard
- **Minimum shippable** = intro + ? days + reunion. One? Two?
- Weekend target: 3? 4–5 only if each day is cheap to author (same systems, new path + new needs).
- **Run length for a first-time judge:** ~3 min · ~6 min · ~10 min. (Day length in 3.7 follows from this.)
- **Expected fails on day 1:** zero · a couple · whatever playtests say.
- Write the **cut order** — which day disappears first if Saturday runs long.

#### 3.5 Do the two needs interact? *(can wait until after the first real day)*
- **Independent** — two checkboxes, no interplay. Least code; the thesis lives in the content, not the rules.
- **Mutual buff** — satisfying one makes the other easier (e.g. fed body runs faster; calmed head rolls slower). Puts the thesis into the mechanics.
- **Shared resource** — both draw on one meter. The brainstorm's *spectrum* idea: the further apart head and body are, the faster/more chaotic/more fragile; the closer, the slower/more controlled/tankier.

#### 3.6 The chase & the camera
- Does the body **platform** (jumps, gaps, hazards) or mostly run and interact? *(decide tonight — it shapes the body controller)*
- Head speed: constant? Pauses at beats (a fork, a cliff, a distraction)?
- Camera follows the head (locked) — how far ahead does it look? Smoothing? Vertical follow? *(these are `@export` numbers; tune when it exists)*
- A *catch-up* mechanic when you fall behind, or is falling behind simply the fail?

#### 3.7 The Sun, the HUD, and the night
- How does the player read need status — two icons that light up? diegetic (the head's face, the body's posture)? both?
- How long is a day, in seconds? The same every day? *(follows from 3.4)*
- How is the Sun shown — an arc across the top? Does sunset tint the world (a `CanvasModulate` node does this in one line)?
- Between days: a night card with the day's name? The body lies down? Straight cut?

#### 3.8 Intrusive thoughts *(can wait for Saturday)*
- **Intro only** — the inciting event, then gone.
- **Recurring hazard** — swarm mid-day; knock the body back, spin the head, flip controls (brainstorm: *controls orientation changes with the head's orientation*).

#### 3.9 Fail & retry feel *(can wait for Saturday)*
- Restart is locked — but how fast? Instant snap-back · a short "try again" card · a beat where the head looks back for you.
- Lose distance: body fully off-screen, or a margin before that?

### B. Code

#### 3.10 Head movement
- `Path2D` + `PathFollow2D` — *pro:* drawn in the editor, same every run, "wait here" markers are a progress ratio. *con:* every pause and beat is hand-placed; the head goes exactly where the line goes.
- Physics (`RigidBody2D` bounce) — *pro:* emergent, funny, zero path authoring. *con:* not the same twice; hard to promise a day is beatable.
- Hand-keyed `AnimationPlayer` — *pro:* precise timing, keyframe spin/squash alongside position. *con:* slow to iterate; the path isn't visible in the 2D view.

#### 3.11 Day authoring
- One base `day.tscn` + an **inherited scene per day** (`day_01.tscn` …) — *pro:* one file per day, one owner. *con:* base-scene changes ripple; scene inheritance has quirks when overriding children.
- One day scene, **data-driven** from a `DayConfig` resource — *pro:* all days in one place, tweak numbers without touching scenes. *con:* one scene everyone edits; twists still need code.
- Freeform scene per day — *pro:* zero constraints. *con:* copy-paste; fixes don't propagate.
- Criterion, not a verdict — since days arrive as ideas come: can a day be added as **one new file, touching no shared scene**?
- **How do you open day 3 directly on Saturday?** Run Current Scene (`F6` / `⌘R`) on its `.tscn` · a debug day-select hidden behind `OS.is_debug_build()` · always replay from the intro.

#### 3.12 Needs
- A `Need` base (`extends Node`, `signal satisfied`, `enum Kind { BODY, MIND }`) with tiny subclasses per verb (pickup, proximity, deliver, switch…) — *pro:* adding a verb = one small file. *con:* more files/classes up front.
- An enum + `match` in the day script — *pro:* one place, fast to type. *con:* one file three people edit.

### C. Team & admin

#### 3.13 Sound
- Who owns it? Sources: jsfxr / ChipTone for SFX, Kenney / freesound CC0, or hand-made. Music: one loop per day, or one loop total?

#### 3.14 Art direction
The one rule: **no generative art.** Otherwise open.
- **Pixel art** — matches the current 640×360 / nearest-filter config. Small canvas = fast to draw; a skeleton reads well at 16–32 px.
- **Hand-drawn / scanned / vector** — switch the viewport to 1280×720 (or 1920×1080), texture filter to Linear, pixel snap off (README says how). Bigger textures → watch web load times.
- **Flat shapes / Godot primitives** (`Polygon2D`, `ColorRect`, `Line2D`) — no drawing pipeline at all; can look intentional with a good palette.
- **Free asset packs** (CC0 / CC-BY: Kenney, OpenGameArt, itch free assets) — check the jam's rules on third-party assets and credit them on the itch page.
- Whoever draws: pick a palette and a canvas size tonight so everyone's placeholders match the final scale.

#### 3.15 Controller & browsers
- Gamepad is already mapped. Test it · ignore it.
- Browser test matrix: Chrome only · + Firefox · + Safari. (Note: `pause` = Esc also exits browser fullscreen — keep, or remap?)

#### 3.16 How we work this weekend
This jam is partly about learning how you work together — decide it on purpose.
- **Sync cadence:** a 5-minute stand-up every ~3 h · at meals · only when someone's blocked.
- **Where tasks live:** GitHub Issues · a `TASKS.md` in the repo · a pinned Discord message. One place.
- **Tiebreak when two of you disagree and time's up:** majority (three people, no ties) · the §6 owner of that area decides · cheapest option wins. Pick tonight — you'll want it at 01:00.
- **Stuck rule:** how long alone on a Godot unknown before you say so — 15 · 30 · 60 min? Then: pair · ask an LLM · park it.
- **Review:** none · glance at each other's diffs at sync · only for shared files.
- **Outside eyes:** a friend plays via the itch secret URL Saturday evening · only each other · nobody.
- *Proposed house rules — strike any you don't want:* say it in Discord before opening a `.tscn` someone else made · commit + push before bed or stepping away, leaving `main` runnable · shared config (`project.godot`, `export_presets.cfg`) has one owner.

#### 3.17 Jam admin — one owner, ten minutes tonight (in parallel with the above)
- Re-read the jam rules: third-party assets and credits, the no-generative-art rule, team registration, submission format.
- **Deadline timezone** — confirm "Sun 10:00" is right in the jam's clock.
- Create the itch project tonight as **Restricted** with a secret URL (*Draft* is visible only to the owner — teammates couldn't test it), or add teammates as project admins. Join the jam page; note what submit needs (screenshots, short description, theme statement).
- **"Submittable" means:** runs from the itch URL in Chrome + Firefox (+ Safari?) · no softlock in any day · controls shown (itch page · in-game · both). **Who presses Submit?** Is every Saturday-evening upload a valid fallback if Sunday's export breaks?

#### 3.18 Idea bank (appendix, from brainstorm.md, unsorted — steal freely)
- WarioWare with two things going on at once
- "What happens to the head will also happen to the body"
- Only the head can see what's going on · minigames seen from the head's perspective
- Bullet hell: head attacks only work on head enemies, body attacks only on body enemies
- Head solves puzzles, body runs/dodges/fights — could they switch roles?
- Stances: zen & in tune vs. berserker & separated — or a spectrum (see 3.5)
- Controls orientation changes with the head's orientation
- The head falls in love · the body falls in love
- What if the head can't see? · only hears? · the body is hurt? · hungry?
- Totally 2D, then the head faces the camera and the guy walks into the screen

---

## 4. Making a first jam succeed

Honest advice, in priority order.

1. **Bookends first, then the loop stays whole.** You've agreed to build the intro and reunion first — put a **stub day** between them so intro → day → reunion runs end to end **Friday night**. From then on the game is always complete and every new day is an insert, never a rewrite. Coloured rectangles for everything; every hour after that goes into *days, art, sound, juice* — not new systems.
2. **Export to the web tonight, then every few hours.** Web is where jam builds die (renderer, audio, threads, load time). The pipeline is proven on Tucker's machine — `tools/export_web.sh` → upload to a **Restricted** itch page (secret URL; *Draft* is owner-only) tonight so Sunday has zero surprises. On web, `print()` goes to the browser devtools console, and keys only arrive once the canvas has focus (click it first). Keep the last known-good `web.zip` in Discord.
3. **One owner per scene file.** `.tscn` merges are the worst part of Godot-in-a-team. Say "I'm in `day_02.tscn`" in Discord before you open it. Scripts merge fine. `project.godot` (input map, autoloads) and `export_presets.cfg` are shared files too — give them an owner. After `git pull` with the editor open: **Scene → Reload Saved Scene**, or restart Godot. If Godot re-saves a `.tscn` you didn't touch, `git checkout -- <file>` before committing. First-timer time sinks to timebox at ~45 min: TileMap/TileSet editor, AnimationTree, shaders, `RigidBody2D` tuning.
4. **Small commits, straight to `main`, fix forward.** No branch ceremony this weekend.
5. **Pick the cut order while you're calm** (tonight). e.g. last day → intro cutscene (→ text card) → ending cutscene (→ text card) → music → … Write it in §2 once chosen.
6. **Timebox tasks to ~2 h.** If it's not done, ship what works or cut it. Polishing one thing for 5 hours is how jams are lost.
7. **Placeholder art until the mechanic it's for is stable.** Code stabilises against rectangles; art swaps in behind stable code (§5 puts that Saturday afternoon). Swapping `ColorRect` → `Sprite2D` changes bounds, pivots, and collision feel — budget an hour for it, body and head first. Art that arrives before the mechanic is locked gets redrawn.
8. **Sleep Saturday night.** With a 10:00 Sunday deadline, Saturday evening is the last real build session — plan it that way.
9. **Feature-freeze Saturday night; submit by ~08:30 Sunday.** Uploads fail, the clock is cruel, itch is slow at deadline. Sunday morning = final playtest, export, page, submit.
10. **The itch page is part of the game.** GIF/screenshot, controls, one line on how it hits the theme. Judges read it before they play.

**Godot, for people who already program:** the ten-line mental model and a glossary are in README → *Godot in ten lines*. "Your first 2D game" in the official docs is a 1-hour read that covers 80 % of what we need: https://docs.godotengine.org/en/stable/getting_started/first_2d_game/

---

## 5. Suggested schedule

Clock: Fri 10:00 → **Sun 10:00**. Team on site from ~Fri 16:00. Adjust to reality and write the real one here.

| When | Goal |
|---|---|
| **Fri 16:00–18:00** | Read this. Decide §3 (timebox it). Fill §6 roles. Everyone: open the project, run it, make one commit. First web export → **draft itch page**. |
| **Fri 18:00–late** | **Intro + reunion** (agreed build order) with a stub day between, so the whole arc runs end to end. Rectangles. Day system skeleton (sun, needs, fail/restart) if time. Web export before bed. **Agree a hard stop.** |
| **Sat 10:00** | Ten minutes playing Friday's *web* build together before anyone codes. |
| **Sat morning** | First real day(s) from the day cards. Finish the day system. |
| **Sat 14:00** | Scope check — apply the cut order now, not at 23:00. |
| **Sat afternoon** | More days as cards are ready. Art swaps in (budget an hour for the swap). |
| **Sat 19:00–21:00** | Itch page text, screenshots, GIF — while the art is in and before you're tired. Not Sunday. |
| **Sat evening** | Reunion polish. Sound. **Feature freeze ~21:00.** Web export → itch updated. Play each other's days, fix what's broken. **Sleep.** |
| **Sun 07:00–08:30** | Final playtest on the *web build* in two browsers. Showstoppers only. Export, **submit by 08:30**. |
| **Sun 10:00** | Deadline. |

---

## 6. Roles (fill in tonight)

| Area | Owner | Notes |
|---|---|---|
| Body movement & feel | | run, jump, interact, buffs |
| Head path & day flow | | head on rails, sun timer, needs, win/fail, day transitions |
| Day authoring | | one owner per day, however days end up stored (§3.11) |
| Art | | skeleton, head, environment, sun, HUD |
| Sound | | SFX, music |
| UI / HUD | | need indicators, sun, fail/win cards |
| Intro & reunion | | |
| Export, itch page, playtest, jam admin | | owns `tools/export_web.sh` runs, the itch page, rules/deadline check (§3.17) |
| Shared config | | `project.godot` (input map, autoloads) and `export_presets.cfg` — one owner; others ask first |

Everyone: commit often, journal in Discord what you're touching, playtest each other.

---

## 7. Conventions

See [README.md](../README.md) — folders, naming, input actions, export steps, git rules. Short version: input via actions, not keys; tunables as `@export`; scripts next to their scenes; commit `.import`/`.uid`, never `.godot/` or `build/`; one owner per `.tscn`.

*Original brainstorm: [brainstorm.md](../brainstorm.md). LLM working agreement: [CLAUDE.md](../CLAUDE.md). LLM activity log: [claudeWorkJournal.md](../claudeWorkJournal.md).*
