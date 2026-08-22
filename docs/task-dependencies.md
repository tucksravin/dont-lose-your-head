# Task dependencies

What has to exist before what. The task list is [TASKS.md](TASKS.md) (same IDs); this is the *order* view. Built from [DESIGN.md](DESIGN.md) §2 after Friday's meeting — if a node here isn't in the Google Doc, add it there or delete it here. GitHub renders the chart; in VS Code you need a Mermaid preview extension, or read the text version below.

**Critical path:** *head roll/stuck/release (T2) → day template (T8) → day 1 (C2) → days 2–5 (C3) → reunion (C5) → submit (P4).* Art and sound run beside it and gate the *look*, not the *code*. Decisions D1–D4, D6, D7 are answered (✔); only **D5 fail details** is open, with a stated default.

```mermaid
flowchart TD
  subgraph D["Decisions (✔ = answered)"]
    D1["✔ D1 Deadline: Sat 23:59"]
    D2["✔ D2 Head = physics (RigidBody2D)"]
    D3["✔ D3 Fixed camera per scene"]
    D5["D5 Fail details — OPEN<br/>default: timer only, instant restart"]
    D6["✔ D6 Pixel art 640×360"]
    D7["✔ D7 Win nodes body/mind, shown on HUD"]
    D4["✔ D4 PRs: anyone merges, self-merge if needed"]
  end

  subgraph T["Scene template — Sean, Ben"]
    T1["T1 Body controller<br/>run / jump / slopes"]
    T2["T2 Head: roll in → stuck on snag<br/>→ release → roll out"]
    T3["T3 Sun timer + arc<br/>timeout → restart day"]
    T4["T4 Keyed win-condition nodes<br/>day complete when all satisfied"]
    T5["T5 Day flow<br/>day list · next · restart (Game autoload)"]
    T6["T6 Camera"]
    T7["T7 HUD: instruction text<br/>+ need status"]
    T8["T8 Day template scene<br/>slope in · flat middle · slope out"]
  end

  subgraph C["Content"]
    C1["C1 Day cards ×~5<br/>one idea each"]
    C2["C2 Day 1 scene<br/>= minimum ship"]
    C3["C3 Days 2–5 scenes<br/>one file each"]
    C4["C4 Intro beat<br/>head falls, starts down"]
    C5["C5 Reunion beat"]
  end

  subgraph A["Art — Tucker"]
    A1["A1 Palette · resolution<br/>skeleton + head sprites"]
    A2["A2 Kiki / bouba<br/>intrusive-thought shapes"]
    A3["A3 Per-day props · sun · HUD art"]
  end

  subgraph S["Sound — Tucker, Ben"]
    S1["S1 SFX"]
    S2["S2 Per-day music"]
  end

  subgraph P["Ship"]
    P1["P1 Web export + Restricted itch page<br/>tonight, then recurring"]
    P2["P2 Playtest rounds"]
    P3["P3 Remove instruction text<br/>where it reads without it"]
    P4["P4 Submit"]
  end

  subgraph X["Stretch"]
    X1["X1 Mental task + physical task per day"]
    X2["X2 Final battle vs intrusive thoughts"]
  end

  D2 --> T2
  D3 --> T6
  D5 --> T3
  D7 --> T4
  D6 --> A1
  D4 -. unblocks merging .-> T8

  T1 --> T8
  T2 --> T8
  T3 --> T8
  T4 --> T8
  T5 --> T8
  T6 --> T8
  T7 --> T8

  T8 --> C2
  C1 --> C2
  C2 --> C3
  C1 --> C3

  T1 --> C4
  T2 --> C4
  A1 --> C4
  A2 --> C4
  C3 --> C5
  A1 --> C5

  A1 --> A3
  A3 --> C3

  C2 --> S1
  C3 --> S2

  C2 --> P2
  C3 --> P2
  P1 -. every few hours .-> P2
  P2 --> P3
  P2 --> P4
  D1 --> P4
  C4 --> P4
  C5 --> P4

  C3 -.-> X1
  C5 -.-> X2
  A2 -.-> X2
```

## Unblocked right now (no arrows in, or only from the template that already exists)

- **D5** fail details is the only open decision — and it has a default, so nothing waits on it.
- **T1** body controller, **T2** physics head, **T3** sun timer, **T4** win nodes, **T5** day flow, **T6** camera, **T7** HUD — all buildable tonight with rectangles, independent of each other; they meet in **T8**.
- **C1** day cards — anyone, any time; the earlier they exist the earlier days 2–5 can start.
- **A0/A1** art direction + sprites (pixel 640×360 confirmed); **A2** kiki/bouba shapes any time after.
- **P1** — make the Restricted itch page tonight and upload the template's `web.zip` to prove the pipeline.

## Text version (same graph)

| Task | Needs first |
|---|---|
| T2 head roll/stuck/release | D2 |
| T3 sun timer | D5 |
| T4 keyed win nodes | D7 |
| T6 camera | D3 |
| T8 day template | T1–T7 |
| C2 day 1 | T8, C1 |
| C3 days 2–5 | C2, C1, A3 (for final look) |
| C4 intro beat | T1, T2, A1, A2 |
| C5 reunion beat | C3 (at least the last day), A1 |
| A1 palette/sprites | D6 |
| A3 per-day art | A1 |
| S1 SFX | C2 (a scene to put it in) |
| S2 per-day music | C3 |
| P2 playtests | C2, then C3; a fresh P1 each round |
| P3 remove text | P2 |
| P4 submit | D1, P2, C4, C5 |
| X1, X2 stretch | C3 / C5 + A2 |
