# Palette — Gooseberry Ghost (+ bone shadow, + violet ramp)

`gooseberry-ghost-plus-bone-shadow.gpl` — load it in **Aseprite**: Palette menu (the ▸ beside the swatches) → *Load Palette…* → pick this file. Or drag `…-.png` onto the palette bar; it reads the swatches straight off the image.

`gooseberry-ghost-plus-bone-shadow.png` — 384×32, one 32×32 swatch per colour, in the order below. Handy for the itch page and for eyedropping in any editor.

| Hex | Use so far |
|---|---|
| `#988277` | sky / background mauve |
| `#645543` | mid brown |
| `#45381c` | dark brown |
| `#201c02` | outline (near-black) |
| `#f1ffaf` | bone (body), sun disc |
| `#cdcd99` | bone shadow — far-side limbs (added by us, not in the original 8) |
| `#b2f167` | light green, sun rays |
| `#25c04b` | mid green |
| `#006a3d` | dark green / ground |
| `#5e2d8c` | violet shadow — kikis only |
| `#8a4fb5` | **violet — intrusive thoughts / kikis** (added Sat 17:xx, Tucker; not in the original 8) |
| `#c79df2` | violet highlight — kikis only |

In code use the named constants in `scripts/colors.gd` (`Colors.VIOLET` …), not hex literals — keep that file and this table in step.

Base palette: **Gooseberry Ghost** by Rustocrat (Lospec), 8 colours; `#cdcd99` and the violet ramp (`#5e2d8c` `#8a4fb5` `#c79df2`, used by `sprites/kikis.png`) are ours. Everything shipped should come from this list — if you need a new colour, add it here and say so, don't one-off it in a scene.
