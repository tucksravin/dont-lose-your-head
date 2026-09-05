# Don't Lose Your Head — Work Journal

Running log of build work: what was done, why, and where it landed.
Chronological — newest entry at the bottom. [CODEBASE.md](CODEBASE.md) is the
map of what the repo contains now; this is the history of getting it there.

The convention is in [CLAUDE.md](../CLAUDE.md) under "The work journal". In
short: every working session appends a dated entry, prose over bullets, why
over what, and history is never edited to be right — a later entry corrects an
earlier one and says so.

This repo already had two journals before this file existed, and both stay:
`journals/<driver>.md` is the per-person log the jam ran on (CLAUDE.md §1), and
`claudeWorkJournal.md` is the frozen Friday shared log. This file is the
project-level record; those are the session-level ones.

---

## 2026-09-05 — Journal opened, and 200 commits of a two-day jam summarised rather than reconstructed (`chore/work-journal`)

The journal starts today, so this first entry is a **backfill**: a deliberately
coarse summary of what came before, written from the commit log rather than
from memory. Detail below this line is trustworthy; detail above it is not, and
nothing here should be cited as though someone wrote it down at the time. The
commit log and the three `journals/*.md` files remain the record for anything
before 2026-09-05.

**What this repo is.** A game-jam entry — Godot 4.7.1, GDScript, pixel art at
640×360, exported to web for itch.io. A skeleton's head is knocked off by
intrusive thoughts; each day the head lands somewhere new and the body has to
chase it, and both body and mind have to be settled before sunset. Theme: *Body
and Mind*. Three people on their first jam, learning Godot while shipping.

**The eras, and there are only two.** All 200 commits fall on two calendar
days — **68 on 2026-08-21, 132 on 2026-08-22** — against a Friday 10:00 →
Saturday 23:59 clock, split Tucker 140, smahre 28, Sean 18, Ben 14. Friday is
scaffold and decision record first (DESIGN.md §2, the task list, the dependency
chart, the working agreement), then the three actors every day instances — body,
head, sun — as placeholder rectangles, then sprites replacing those rectangles
one at a time. It ends with an overnight batch on `night/*` branches merged
through `night/all` into PR #16/#17: the smoke suite, the day-authoring kit and
the `Dev` autoload, an SFX/music scaffold silent until files exist, procedural
animation polish. Saturday is content and cutting — seven day scenes (panic,
still-panic, platforming, lockdown, mirror, velma, workout), the kiki sprite
system and its self-scrambling generator, a scripted opening and landing screen
replacing the bare intro, a forkable bird transition, floor plates you have to
stomp rather than walk over, credits, jump, replay, touch controls. One deletion
still shows in the input map: the `interact` key went on Saturday — you trigger
things by reaching them — and the binding was kept so a later day could pick it
up.

**State as of this entry.** Branch `tucker/touch-controls` at `03012f5`
("Touch controls: a drag stick that appears wherever the finger lands"), which
is one commit off `main`; `main` carries one this branch does not, `42a5734`
("Add credits (#63)"). The tree is otherwise clean, but for one untracked file:
`build/.gdignore`, which .gitignore explicitly negates and whose own comment
says it *is* committed — it was dropped from the tree in #56 and has been
untracked since. Nothing else is in flight.
