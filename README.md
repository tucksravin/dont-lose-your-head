# Don't Lose Your Head

Game jam entry — theme **Body and Mind**. Godot **4.7.1** (standard/GDScript build, not .NET). Target: **itch.io web**.

> A skeleton is assaulted by intrusive thoughts and its head pops off. Each day the Sun rises, something befalls the head, and the body chases after it. Both body and mind have to be taken care of before sunset. At the end, they're reunited.

**Read first:** [docs/DESIGN.md](docs/DESIGN.md) — what's decided (incl. Friday's meeting), what's still open, how we'll run the weekend. Task order: [docs/task-dependencies.md](docs/task-dependencies.md). Friday's raw notes: [meeting-notes-friday.md](meeting-notes-friday.md).

**Where things are:** tasks → [docs/TASKS.md](docs/TASKS.md) and the shared Google Doc *(paste link here)* · chat → Discord · build → itch (Restricted, secret URL in Discord) · **deadline → Sat 23:59, submit by 22:30**.
**If you're an LLM:** read [CLAUDE.md](CLAUDE.md) and log your work in [claudeWorkJournal.md](claudeWorkJournal.md).

## Quickstart

1. Install **Godot 4.7.1** (standard, *not* .NET): https://godotengine.org/download — on macOS it's already at `/Applications/Godot.app`.
2. Clone, then open Godot → **Import** → pick `project.godot` in this folder.
3. First open takes a moment (importing). Then **Run Project** (`F5` / `⌘B` on macOS).
4. You should see "template OK — press a key". Press `A/D/Space/E/R/Esc` or a gamepad: the label names the input action that fired. That's the whole template; the game is yours.
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
| Autoloads | `Events` (signal bus), `Game` (scene flow) | Empty stubs with TODOs in `scripts/autoload/` |
| Input actions | `move_left` `move_right` `jump` `interact` `restart` `pause` | Keyboard + gamepad bound (see below). Use `Input.is_action_pressed("jump")`, never raw keys. |
| Web export preset | `export_presets.cfg` → "Web", threads **off** | Runs on itch.io without SharedArrayBuffer headers; works from a plain local http server |

**If that ever changes** (it's decided — pixel art): Project → Project Settings (turn on *Advanced Settings*): set `display/window/size/viewport_width|height` to 1280×720 or 1920×1080, `rendering/textures/canvas_textures/default_texture_filter` to **Linear**, and turn off both `rendering/2d/snap/*` options. Keep GL Compatibility — that one is for the web, not for pixels.

### Input map

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_left` / `move_right` | A / D, ← / → | Left stick X, D-pad |
| `jump` | Space, W, ↑ | A (bottom face button) |
| `interact` | E, ↓ | X (left face button) |
| `restart` | R | Back/Select |
| `pause` | Esc | Start |

Edit in **Project → Project Settings → Input Map**.

## Folder layout

```
project.godot          engine config (edit via Project Settings, not by hand, when possible)
export_presets.cfg     web export preset
scenes/                one folder per thing; keep a scene's .gd next to its .tscn
  main.tscn/.gd        boot scene (placeholder) — repoint run/main_scene when the real entry exists
  body/  head/  days/  ui/
scripts/autoload/      Events, Game singletons
assets/sprites|audio|fonts
tools/export_web.sh    headless web export + zip for itch
build/                 export output (git-ignored, except build/.gdignore — keeps Godot from importing old builds)
docs/DESIGN.md         design doc
docs/TASKS.md          the task list (IDs, owners, sizes, done-when)
docs/task-dependencies.md  what blocks what (Mermaid)
docs/days/brainstorm.md    day ideas scratchpad (team)
brainstorm.md          original brainstorm
meeting-notes-friday.md    Friday kickoff decisions (source for DESIGN §2)
CLAUDE.md              instructions for LLM assistants
claudeWorkJournal.md   running log of everything an LLM did in this repo
```

## Smoke tests (run before a PR)

```sh
tools/smoke_test.sh          # ~1 min, headless, prints SMOKE: ALL GREEN or RED
tools/smoke_test.sh --web    # also runs the web export and checks the output
tools/smoke_test.sh play_through   # one suite by name
```

Five suites in `tools/smoke/` (each is a plain `SceneTree` script run with `-s`): **load_all** — every scene/script/resource loads and every `ext_resource` path exists · **day_lint** — every `scenes/days/*.tscn` has one head, one body, a Sun, a camera, a win-condition manager and ≥1 `WinCondition`; `Game.DAY_SCENES` entries exist and are ordered legally · **day_chain** — force-satisfies each day's needs and asserts the chain reaches the reunion · **day_sunset** — each day reacts to sunset, and a *won* day ignores it · **play_through** — a bot presses the real input actions and plays intro → every day → reunion → end card; a day whose plan can't be executed goes red (update its plan in `play_through.gd` when you change a layout). `tools/smoke/known_broken.txt` lists scenes allowed to be broken, one justified line each — keep it short.

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
