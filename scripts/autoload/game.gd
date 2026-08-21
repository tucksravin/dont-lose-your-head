extends Node
## Game-wide state and scene flow (autoload: `Game`).
##
## Intended home for: current day index, moving between intro / days / ending,
## restarting the current day. Keep it small — anything that belongs to one scene
## should live in that scene.
##
## TODO(team): fill in once the day loop is designed (see docs/DESIGN.md §3).

## Load a scene by path. Thin wrapper so call sites don't reach for the tree directly.
func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)
