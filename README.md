# Don't Lose Your Head

Game jam entry — theme **Body and Mind**. Godot **4.7.1** (standard/GDScript build, not .NET). Target: **itch.io web**.

> A skeleton is assaulted by intrusive thoughts and its head pops off. Each day the Sun rises, something befalls the head, and the body chases after it. Both body and mind have to be taken care of before sunset. At the end, they're reunited.

**Read first:** [docs/DESIGN.md](docs/DESIGN.md) — what's decided (incl. Friday's meeting), what's still open, how we'll run the weekend. Task order: [docs/task-dependencies.md](docs/task-dependencies.md). Friday's raw notes: [meeting-notes-friday.md](meeting-notes-friday.md).

**Where things are:** tasks → [docs/TASKS.md](docs/TASKS.md) and the shared Google Doc *(paste link here)* · chat → Discord · build → itch (Restricted, secret URL in Discord) · **deadline → Sat 23:59, submit by 22:30**.
**If you're an LLM:** read [CLAUDE.md](CLAUDE.md) and log your work in `journals/<driver>.md` (one file per person; `claudeWorkJournal.md` is the frozen Friday log). **Map of the code:** [docs/CODEBASE.md](docs/CODEBASE.md).

## Quickstart

1. Install **Godot 4.7.1** (standard, *not* .NET): https://godotengine.org/download — on macOS it's already at `/Applications/Godot.app`.
2. Clone, then open Godot → **Import** → pick `project.godot` in this folder.
3. First open takes a moment (importing). Then **Run Project** (`F5` / `⌘B` on macOS).
4. You should land in the **intro**: a head running right, you chasing it (`A/D` move, `Space` jump). When it leaves the screen the days start. `F9` shows the debug overlay, `F7` skips to the next scene (debug builds only). The old "template OK — press a key" screen is `scenes/main.tscn`, now only the placeholder after the reunion.
5. **Tonight, while on wifi:** Editor → **Manage Export Templates → Download and Install** (≈1 GB, one-time) so `tools/export_web.sh` works on *your* machine too. Sanity check from a terminal: `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 60` should print no errors.
6. Editing scripts: Godot's built-in script editor is fine. If you'd rather use VS Code, install the **godot-tools** extension and set `godotTools.editorPath.godot4` to `/Applications/Godot.app` (that lives in `.vscode/`, which is git-ignored). `F5`/`⌘B` runs the project, `F6`/`⌘R` runs the scene you have open.

## Godot in ten lines (for people who already program)

Everything is a **Node**; a **Scene** (`.tscn`, a text file) is a saved node tree you can instance like a prefab; a **script** (`.gd`) attaches to one node; nodes talk via **signals** (built-in observer pattern); `@export var` shows a variable in the **Inspector** (the property panel on the right); **autoloads** are singletons you name in Project Settings; `_process(delta)` runs every frame, `_physics_process(delta)` at a fixed 60 Hz; `CharacterBody2D` + `move_and_slide()` for a controllable body, `Area2D` for triggers/pickups, `Camera2D` for the camera, `Path2D`/`PathFollow2D` for "move along a drawn line"; `create_tween()` for quick animations, `AnimationPlayer` for keyframed ones; a **Resource** (`.tres`) is a data asset. Sidecars: `.import` (next to assets) and `.uid` (next to scripts) are generated — **commit them**; `.godot/` is the cache — never commit it. Docs: https://docs.godotengine.org/en/stable/ — start with "Your first 2D game".

## What's already configured

| Thing | Value | Why |
|---|---|---|
| Viewport | 640×360, window opens at 1280×720 | **Decided Friday: pixel art at 640×360** ([DESIGN.md §2.1](docs/DESIGN.md)). Scales 2×/3× cleanly to 720p/1080p |
| Stretch | `canvas_items` / `keep` | Sprites scale with nearest filtering, UI text stays crisp. Letterboxes on odd aspect ratios. (Prefer true integer scaling? set `display/window/stretch/scale_mode = integer` in Project Settings.) |
| Texture filter | Nearest (pixel-perfect) | Pixel art |
| 2D pixel snap | On (transforms + vertices) | No half-pixel shimmer |
| Renderer | **GL Compatibility** | Required for web export — Forward+ does not run in browsers |
| Autoloads | `Events` (signal bus), `Game` (scene flow), `Dev` (F-keys + overlay, debug builds only), `Sfx` (sounds by cue name), `Music` (a track per scene) | `scripts/autoload/` — all implemented; see [docs/CODEBASE.md §3](docs/CODEBASE.md) |
| Input actions | `move_left` `move_right` `jump` `move_down` `restart` `pause` (`interact` is still bound but unused — see below) | Keyboard + gamepad bound (see below). Use `Input.is_action_pressed("jump")`, never raw keys. |
| Web export preset | `export_presets.cfg` → "Web", threads **off** | Runs on itch.io without SharedArrayBuffer headers; works from a plain local http server |

**If that ever changes** (it's decided — pixel art): Project → Project Settings (turn on *Advanced Settings*): set `display/window/size/viewport_width|height` to 1280×720 or 1920×1080, `rendering/textures/canvas_textures/default_texture_filter` to **Linear**, and turn off both `rendering/2d/snap/*` options. Keep GL Compatibility — that one is for the web, not for pixels.

### Input map

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_left` / `move_right` | A / D, ← / → | Left stick X, D-pad |
| `jump` | Space, W, ↑ | A (bottom face button) |
| `interact` | E, ↓ | X (left face button) — **unused: nothing in the game reads it** (Sat, Tucker: no use key; you trigger things by reaching them). Binding kept so a day can pick it up again. |
| `move_down` | ↓ | D-pad down — mirror day only: jump while the head stares at the glass |
| `restart` | R | Back/Select |
| `pause` | Esc | Start |

Edit in **Project → Project Settings → Input Map**.

**Dev keys (debug builds only — editor and headless, never the web export):** F1 satisfy body need · F2 mind need · F3 all · F4 fail the day · F5 restart · F6/F7 previous/next scene in the run · F8 reunion · F9 debug overlay (needs, sun %, panic, body position) · F10 slow motion. They live in `scripts/autoload/dev.gd` (`Dev` autoload) and register themselves as `debug_*` actions at runtime, so the input map above stays gameplay-only.

**Making a day:** [docs/days/HOWTO.md](docs/days/HOWTO.md) — the 5 steps and the numbers to design against (jump height, reach, floor line, palette).

## Folder layout

Full map with links and contracts: **[docs/CODEBASE.md](docs/CODEBASE.md)**. Short version:

```
project.godot          engine config — 640×360, input map, autoloads (Events, Game, Dev, Sfx, Music)
export_presets.cfg     the one "Web" preset (threads off; excludes tools/*)
default_bus_layout.tres  audio buses Master → Music, SFX
scenes/                one folder per thing; a scene's .gd lives next to its .tscn
  body/  head/  sun/   the three actors every day instances (+ body_juice.gd)
  gameplay/            WinCondition + the two managers, DayManager, SpatialGoal, PanicCounter, sky_drift
  days/                one .tscn per day (day_template is the one to copy); platforming_day.gd; day_01.tscn = broken leftover
  transition/          head-rolls-downhill beat (base + inherited forks)
  intro/  reunion/  ui/   first beat, last beat, game-over card; reunion/preview/ = sprite check
  main.tscn/.gd        old boot placeholder — today only the screen after the reunion (needs an end card)
scripts/autoload/      the five singletons
assets/sprites|palette|audio|fonts   art + .aseprite sources, the 9-colour palette, audio drop folders (empty), fonts (empty)
tools/smoke_test.sh    the smoke suite (tools/smoke/*.gd) — run before a PR
tools/export_web.sh    headless web export + zip for itch
build/                 export output (git-ignored, except build/.gdignore)
docs/CODEBASE.md       what's in the repo and how it fits (this is the map)
docs/DESIGN.md         design doc — §2 is the decision record
docs/TASKS.md          the task list (IDs, owners, sizes, done-when)
docs/task-dependencies.md  what blocks what (Mermaid)
docs/days/HOWTO.md     how to make a day + the numbers to design against
docs/days/brainstorm.md    day ideas scratchpad (team)
docs/overnight-2026-08-22.md   the overnight run's report + stand-up agenda
journals/<name>.md     one work journal per person (LLM sessions append here)
brainstorm.md · meeting-notes-friday.md   Friday sources (DESIGN §2 defers to the notes)
CLAUDE.md              instructions for LLM assistants
claudeWorkJournal.md   the original Friday LLM log — frozen
```

## Smoke tests (run before a PR)

```sh
tools/smoke_test.sh          # ~1 min, headless, prints SMOKE: ALL GREEN or RED
tools/smoke_test.sh --web    # also runs the web export and checks the output
tools/smoke_test.sh play_through   # one suite by name
```

Six suites in `tools/smoke/` (each is a plain `SceneTree` script run with `-s`): **load_all** — every scene/script/resource loads and every `ext_resource` path exists · **day_lint** — every `scenes/days/*.tscn` has one head, one body, a Sun, a camera, a win-condition manager and ≥1 `WinCondition`; `Game.DAY_SCENES` entries exist and are ordered legally · **day_chain** — force-satisfies each day's needs and asserts the chain reaches the reunion · **day_sunset** — each day reacts to sunset, and a *won* day ignores it · **play_through** — a bot presses the real input actions and plays intro → every scene → reunion → the scene after it; a day whose plan can't be executed goes red, a day with no plan is force-satisfied with a warn (add a plan in `play_through.gd` once a layout is stable) · **audio** — buses exist, cue names are legal, cues fire at the right moments. `tools/smoke/known_broken.txt` lists scenes allowed to be broken, one justified line each — keep it short.

## Exporting to itch.io

**From the editor:** Project → Export → Web → *Export Project…* → pick `build/web/index.html` → zip the contents of `build/web/`.

**From a terminal (preferred, same result):**

```sh
tools/export_web.sh            # → build/web.zip
# test locally first:
python3 -m http.server -d build/web 8000   # open http://localhost:8000
```

If export says templates are missing: Godot → **Editor → Manage Export Templates → Download and Install** (≈1 GB, one-time). Tucker's machine already has 4.7.1 templates.

**On itch.io** (new project): Kind of project **HTML** → upload `web.zip` → tick **"This file will be played in the browser"** → Embed: viewport **1280 × 720**, enable fullscreen button. Leave *SharedArrayBuffer support* unchecked (threads are off in the preset). Visibility: **Restricted** with the secret URL shared in Discord (a *Draft* is visible only to the owner, so teammates couldn't test it) — prove the pipeline tonight, make it public at submission.

Web gotchas to keep in mind: audio can't start until the player clicks/presses something (Godot handles this, but don't design a silent-until-input intro that needs sound); keyboard input only arrives once the canvas has focus (click it); `print()` shows up in the browser devtools console; Esc also exits browser fullscreen; large textures load slowly; `OS.execute`, arbitrary OS file paths, and real multithreading don't work on web (`user://` does — it's backed by IndexedDB; `Thread` just runs synchronously with threads off).

## Git conventions (jam edition)

- **Branch per task, PR into `main`** (team decision Friday). Keep PRs small and short-lived — hours, not days; a `.tscn` sitting on a branch overnight is a conflict in the morning. Merge rules (DESIGN §2.3): anyone can merge someone else's PR; self-merge if necessary.
- `.import` and `.uid` files **are committed** (they sit next to assets/scripts). `.godot/` and `build/` are **ignored**.
- **One owner per `.tscn` file.** Scene files merge badly. Before editing a scene someone else made, say so in Discord. Scripts (`.gd`) merge fine.
- Naming: `snake_case` for files and variables, `PascalCase` for node names and `class_name`s. Scene and its script share a name (`body.tscn` + `body.gd`).
- Tunables (`speed`, `jump_height`, `day_length`) as `@export var` so they're editable in the Inspector without code changes.
