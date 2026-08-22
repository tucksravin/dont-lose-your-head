# Audio — what to make, where to put it

Everything below Sfx.CUES is already wired. **Drop a file in with the right name and it plays.** Nothing else to touch. Until a file exists its cue is silent (no error), and the game prints the missing list at boot:
`Sfx: 15/15 cues have no file yet — …`

**Jump and footsteps are the exception** — they're wired directly on the Body node (`scenes/body/body.gd`: `jump_sounds` array on `JumpSound`, the loop on `Sound`), not through `Sfx.CUES`. `jump`: light hop / bone click, ~80 ms, one-shot, cycled on every jump — several short variants (`assets/audio/sfx/jump/jump_1.wav`, `jump_2.wav`, …) read better than one file playing on repeat; add more and assign them in `body.tscn`'s `jump_sounds` array (order = play order, not random). Footsteps: `assets/audio/sfx/walk/walk_2.wav`, looped while the body is moving on the ground.

## SFX — `assets/audio/sfx/<cue>.wav` (or `.ogg`)

One-shots. **WAV, mono, 44.1 kHz, 16-bit**, trimmed tight (no leading silence — it fires on the frame). Short: most of these want 50–300 ms. Palette-wise think *silly-spooky*: bone clacks, hollow knocks, kazoo-adjacent, nothing wet.

| cue (file name) | fires when | suggestion | ~length |
|---|---|---|---|
| `land` | body touches down | dull knock; heavier than jump | 100 ms |
| `step` | each walk-cycle foot (optional — only if a file exists) | tiny tick | 40 ms |
| `need_met` | one of the day's two needs satisfied | bright blip, major | 200 ms |
| `day_won` | both needs met, head released | 2-note rising "ta-da", small | 400 ms |
| `head_roll` | the head starts rolling away | rattle / marble on wood, one-shot not loop | 500 ms |
| `day_failed` | day lost (sunset, pit, panic maxed) | descending 2-note "womp" | 400 ms |
| `sunset_warning` | 5 s before sunset, once | low tick-tock or a single low tone | 300 ms |
| `panic_tick` | panic meter moves by 1 (pitch rises with panic automatically) | single heartbeat thump | 120 ms |
| `calm` | panic reaches zero | soft exhale / chime | 400 ms |
| `bridge_drop` | bridge lands (platforming day) | wood thunk + creak | 400 ms |
| `dive` | body leaps for the head (reunion) | whoosh | 300 ms |
| `reunite` | body lands on the head (reunion) | satisfying clack + little chord | 500 ms |
| `cage` | cage drops on the head (transition) | metal clang | 400 ms |
| `thud` | head stops rolling on the slope (transition) | soft thud | 150 ms |
| `ui_confirm` | retry button / menu | click | 60 ms |

Not wired yet, worth recording anyway: **`pop`** (head comes off — the intro beat, not built), **`intrusive`** (kiki shape appears), **`roll_loop`** (continuous roll, for the transition — if we want it, it needs a looping player; say so).

## Music — `assets/audio/music/<track>.ogg`

Loops. **OGG Vorbis, ~128–160 kbps, 44.1 kHz**, stereo fine. Make the loop point clean (the file loops end→start as-is; the game switches looping on at runtime). Tracks crossfade over 0.8 s when the scene changes.

| track (file name) | plays in | notes |
|---|---|---|
| `intro` | intro scene | head falls off, chase |
| `day` | **any day that doesn't name its own track** | the all-purpose day loop — make this one first |
| `day_panic` *(example)* | a day that sets `@export var music_track = &"day_panic"` on its root script | per-day music is an export on the day; no code |
| `transition` | the head-rolls-down-the-slope beat (~5 s, longer if the player dawdles — the body is theirs there) | short; could be a sting rather than a loop |
| `reunion` | the reunion | resolve |

## Format / web gotchas
- Web export can't start audio until the player has clicked or pressed a key; cues before that are lost. **The intro plays hands-free**, so on the web it is silent and sound starts with the first keypress in day 1 (a press-any-key title screen — TASKS X4 — would fix that).
- Keep total audio under a few MB; the web build loads everything up front.
- Buses: `Master` → `Music`, `SFX` (`default_bus_layout.tres`). Mix there, not per file.
- Import: WAV/OGG import with defaults is right. If a WAV sounds clipped, check it's 16-bit PCM.
