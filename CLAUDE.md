# CLAUDE.md — working agreement for LLM assistants in this repo

This is a 48-hour game-jam project ("Don't Lose Your Head", Godot 4.7.1, theme *Body and Mind*) by a three-person team on their **first jam**, who are also using it to **learn Godot** and **learn how they work together**. Those two goals shape everything below.

## 1. Keep the work journal — non-negotiable

After every task (or at a natural stopping point in a long one), append an entry to **`journals/<driver>.md`** — one file per person (e.g. `journals/smahr.md`, `journals/tucker.md`, `journals/ben.md`). One file per person prevents merge conflicts when all three teammates are working in parallel. If the file doesn't exist yet, create it with a one-line header (`# Work Journal — <name>`) and start appending. The team reads these back to understand what was done and why.

Format:

```
## YYYY-MM-DD HH:MM — <short task title>
**Driver:** <who asked — e.g. Tucker> · **Agent:** <model / session if known>
**Asked:** one line, in the human's words where possible
**Did:** what changed, as a short list — files touched, decisions made, anything rejected and why
**Verified:** exactly what you ran and what it showed (or "not verified — <reason>")
**Open:** questions for the team / things left undone / follow-ups
```

Rules: timestamp from the real clock (`date '+%Y-%m-%d %H:%M'`), not a guess; newest entry at the **bottom**; never rewrite old entries (append a correction instead); be honest about what didn't work; link files as paths. If you did nothing but answer a question, a two-line entry is fine.

`claudeWorkJournal.md` is the original shared log — leave it as historical record, don't append to it.

## 2. The team decides design — you present options

Do not invent mechanics, day content, or architecture. When a task needs a design or architecture decision that isn't already in `docs/DESIGN.md`, **stop and ask**, or lay out 2–3 options with trade-offs and let a human pick. Only treat something as decided if it's in DESIGN.md §2 "Locked" or a human says so in the conversation. Record new decisions in DESIGN.md §2 when they're made.

## 3. Teach while you work (they're learning Godot)

When you use a Godot concept, say what it is in a sentence and why you chose it — e.g. "`Area2D` because we only need overlap detection, not physics; `CharacterBody2D` would be overkill." Link the relevant docs page when it's non-obvious (https://docs.godotengine.org/en/stable/). Prefer the idiomatic Godot way over clever workarounds, and name the idiom (signals, scene instancing, `@export`, autoloads, `Tween`, `AnimationPlayer`).

## 4. Verify before you claim — the exact commands

"It should work" is not done. Run the relevant check and report the output:

```sh
G=/Applications/Godot.app/Contents/MacOS/Godot
$G --headless --path . --import                      # imports assets, compiles scripts; must be error-free
$G --headless --path . --quit-after 60               # runs the main scene ~1s; grep output for ERROR/SCRIPT ERROR
$G --headless --path . --quit-after 60 res://scenes/main.tscn   # run one scene (path as last arg). Exit code is 0 even if it failed — grep for ERROR
tools/export_web.sh                                  # full web export; run before claiming anything web-related works
```

Anything involving input, audio, or timing should also be eyeballed by a human in the editor — say so rather than guessing.

## 5. Conventions (summary — details in README.md)

- GDScript, **static typing** (`var speed: float = 200.0`, `func foo() -> void`). Godot 4.7 APIs — not Godot 3 (`move_and_slide()` takes no args; `@export`/`@onready` annotations; `Tween` via `create_tween()`).
- Files `snake_case`, nodes/classes `PascalCase`. A scene's `.gd` lives beside its `.tscn` with the same name.
- Input through actions (`Input.is_action_just_pressed("jump")`), never key codes.
- Tunables are `@export var`s at the top of the script, not magic numbers mid-function.
- Prefer signals (`Events` bus for cross-scene, local signals within a scene) over reaching up the tree with `get_parent()` / `get_node("../../..")`.
- `.import` and `.uid` files are committed. `.godot/` and `build/` are not.
- Don't add addons/plugins or change `project.godot` rendering/display settings without asking.

## 6. Editing scene files

`.tscn` files merge badly. Before editing one: `git log --oneline -3 -- path/to/scene.tscn` to see who owns it, and mention it in your journal entry. Make the **smallest possible diff** — don't reorder nodes, don't reformat, don't let the editor re-save unrelated scenes. Prefer adding behaviour in a `.gd` over restructuring a scene.

## 7. Scope guard

It's a jam. Prefer the smallest change that works. If a request implies a new system, more than ~2 hours of work, or touches the cut order in DESIGN.md §2 (once the team has written it — see §3.4), say so before starting. Flag scope creep kindly; don't silently do it, and don't silently skip it either.

## 8. Communication

Ask one question at a time, with options when possible. If something is ambiguous and reversible, pick the obvious reading, do it, and note the assumption in the journal. If it's ambiguous and hard to undo (deleting scenes, rewriting shared files, changing project settings), ask first. Never commit or push unless asked; the team works in **branches + PRs into `main`**, so if asked to commit, do it on the current branch (never directly on `main` unless told) and say which branch.

## 9. Keep docs true

If you change an input action, folder, convention, or export step, update README.md / DESIGN.md in the same change.
