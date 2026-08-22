# Sprites — how to wire them in (owners of `body.tscn` / `head.tscn`)

All art is 1× pixel art on a 32×32 (body) / 16×16 (head) canvas. **Render at integer scale 2** — that matches the 24×32 / 28×28 placeholders the movement was tuned against (see `scenes/sprites_preview.tscn`, F6).

**Body** (`scenes/body/body.tscn`, floor-origin — feet at y = 0):
1. Replace the `Visual` ColorRect with an **`AnimatedSprite2D`**: `sprite_frames = res://assets/sprites/body_frames.tres`, `animation = "walk"` (also has `idle`, `throw`), `centered = false`, `offset = Vector2(-16, -32)`, `scale = Vector2(2, 2)`. Feet land on the origin; the headless body is 13×19 px at 1× (26×38 on screen).
2. In `body.gd`: `$AnimatedSprite2D.flip_h = velocity.x < 0.0` when moving; play `walk` when `abs(velocity.x) > 1`, else `idle` (add `if` around `play()` so it doesn't restart every frame).
3. Collider: the body is now 26×38 on screen; a `RectangleShape2D` ≈ `Vector2(20, 38)` at `position (0, -19)` hugs it (the old 24×32 was for the rectangle). Tune to taste.

**Head** (`scenes/head/head.tscn`) — **wired**: `Visual` is a `Sprite2D` with `head_front.png`, `scale = (2,2)`, centered (so the release spin in `head.gd` rotates about the skull's middle). The intro uses `head_side.png` instead, because there the head is running to the right. Scripted, not simulated: a frozen `RigidBody2D` moved by code, DESIGN §2.1.
1. Replace `Visual` with a **`Sprite2D`**: `texture = res://assets/sprites/head_front.png` (or `head_side.png`), `scale = Vector2(2, 2)` (centered). 16×16 → 32×32 on screen.
2. The collider shape no longer matters for the roll-off (it's scripted) — keep the rectangle.
3. Rotation: spin the sprite from the release script (`rotation += spin_speed * delta`; jaggies at 2× are mild) or keep it upright and swap frames by angle later (`head_roll.png` isn't made yet).

**Sun** (`scenes/sun/sun.tscn`) — wired: `Visual` is a `Sprite2D`, `texture = res://assets/sprites/sun.png` (Tucker's 16×16, palette #f1ffaf disc / #b2f167 rays), `scale = Vector2(2, 2)`, centered so `Sun.position` is still the arc centre. Source `src/sun.aseprite`.

Texture filtering is Nearest project-wide; nothing to set per sprite. Sources are in `src/` (Aseprite); credits in `CREDITS.md`.

**Palette:** [`assets/palette/`](../palette/README.md) — the `.gpl` to load in Aseprite, and the swatch strip. All shipped art comes from it.

**Where the sprites are wired (Fri 20:30):** body → `scenes/body/body.tscn` · head → `scenes/head/head.tscn` (front) and `scenes/intro/intro.tscn`'s `HeadBlob` (side) · sun → `scenes/sun/sun.tscn`. Backgrounds and floors in `intro` / `day_template` / `reunion` are palette flat colours — all three skies are `#988277` (a background must never be `#201c02`: that is the sprites' own outline colour, and the silhouettes vanish into it); the two `SpatialGoal` markers are still rectangles, coloured per need from `spatial_goal.gd` (`body_color` / `mind_color`) because there's no art for them yet.
