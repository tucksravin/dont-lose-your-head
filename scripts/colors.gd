class_name Colors
extends RefCounted
## Named hex codes for the project palette — Gooseberry Ghost (+ bone shadow),
## assets/palette/gooseberry-ghost-plus-bone-shadow.gpl. Code should reference
## these by name (`Colors.DARK_GREEN`) instead of one-off hex literals, so a
## palette swap is a one-file change. Matches the palette README's rule:
## everything shipped comes from this list — add new colours there first.
##
## `class_name` only, no `extends Node`/autoload registration: this is static
## data with nothing to run per-frame, so it doesn't need a place in the scene
## tree the way Events/Game/Sfx (scripts/autoload/) do. `class_name` alone
## already makes `Colors.SOMETHING` callable from anywhere, unregistered.
## Docs: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html#classes-as-a-resource

const MAUVE_SKY: Color = Color("#988277")
const BROWN: Color = Color("#645543")
const DARK_BROWN: Color = Color("#45381c")
const OUTLINE: Color = Color("#201c02")
const BONE: Color = Color("#f1ffaf")
const BONE_SHADOW: Color = Color("#cdcd99")
const LIGHT_GREEN: Color = Color("#b2f167")
const GREEN: Color = Color("#25c04b")
const DARK_GREEN: Color = Color("#006a3d")
