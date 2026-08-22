# Sprites — how to wire them in (owners of `body.tscn` / `head.tscn`)

All art is 1× pixel art on a 32×32 (body) / 16×16 (head) canvas. **Render at integer scale 2** — that matches the 24×32 / 28×28 placeholders the movement was tuned against (see `scenes/sprites_preview.tscn`, F6).

**Body** (`scenes/body/body.tscn`, floor-origin — feet at y = 0):
1. Replace the `Visual` ColorRect with an **`AnimatedSprite2D`**: `sprite_frames = res://assets/sprites/body_frames.tres`, `animation = "walk"` (also has `idle`, `throw`), `centered = false`, `offset = Vector2(-16, -32)`, `scale = Vector2(2, 2)`. Feet land on the origin; the headless body is 13×19 px at 1× (26×38 on screen).
2. In `body.gd`: `$AnimatedSprite2D.flip_h = velocity.x < 0.0` when moving; play `walk` when `abs(velocity.x) > 1`, else `idle` (add `if` around `play()` so it doesn't restart every frame).
3. Collider: the body is now 26×38 on screen; a `RectangleShape2D` ≈ `Vector2(20, 38)` at `position (0, -19)` hugs it (the old 24×32 was for the rectangle). Tune to taste.

**Head** (`scenes/head/head.tscn`, `RigidBody2D`):
1. Replace `Visual` with a **`Sprite2D`**: `texture = res://assets/sprites/head_front.png` (or `head_side.png`), `scale = Vector2(2, 2)` (centered). 16×16 → 32×32 on screen.
2. A rolling head needs a **`CircleShape2D`** (`radius ≈ 14`) instead of the 28×28 rectangle, or it won't roll.
3. Rotation: either let the body rotate the sprite (jaggies at 2× are mild) or keep the sprite upright and swap frames by angle later (`head_roll.png` isn't made yet).

Texture filtering is Nearest project-wide; nothing to set per sprite. Sources are in `src/` (Aseprite); credits in `CREDITS.md`.
