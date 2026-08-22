class_name Colors
extends RefCounted
## Named hex codes for the project palette — Gooseberry Ghost (+ bone shadow, + violet ramp),
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
## Intrusive thoughts / kikis only (added Sat 17:xx — the one deliberate break
## from Gooseberry Ghost; see assets/palette/README.md).
const VIOLET_SHADOW: Color = Color("#5e2d8c")
const VIOLET: Color = Color("#8a4fb5")
const VIOLET_HIGHLIGHT: Color = Color("#c79df2")
