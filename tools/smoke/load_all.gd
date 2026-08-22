extends SceneTree
## Smoke: every scene, resource and script in the project loads.
##
## Catches the "someone renamed/deleted a file another scene points at" class
## of bug before anyone opens Godot — a .tscn whose ext_resource is missing is a
## hard Parse Error at load, and that error only shows when that scene is opened.
## Two layers: a text-level check that every `path="res://..."` an ext_resource
## names exists on disk (precise message), then a real load() of everything.

const Smoke := preload("res://tools/smoke/smoke_lib.gd")

var _known: Dictionary = {}


func _initialize() -> void:
	_known = Smoke.known_broken()
	var files: Array[String] = []
	Smoke.list_files("res://scenes", ["tscn", "gd", "tres"], files)
	Smoke.list_files("res://scripts", ["gd"], files)
	Smoke.list_files("res://assets", ["tres"], files)
	files.sort()

	for f in files:
		if f.ends_with(".tscn") or f.ends_with(".tres"):
			_check_ext_resources(f)
	for f in files:
		_check_loads(f)

	Smoke.finish(self, "load_all")


## Every ext_resource path named in a text resource must exist.
func _check_ext_resources(path: String) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	var re: RegEx = RegEx.new()
	re.compile("\\[ext_resource[^\\]]*path=\"(res://[^\"]+)\"")
	for m in re.search_all(text):
		var dep: String = m.get_string(1)
		if FileAccess.file_exists(dep):
			continue
		if _known.has(path):
			Smoke.warn("%s → missing %s  [known: %s]" % [path, dep, _known[path]])
		else:
			Smoke.fail("%s → ext_resource not on disk: %s" % [path, dep])


func _check_loads(path: String) -> void:
	if _known.has(path):
		Smoke.warn("%s skipped load  [known: %s]" % [path, _known[path]])
		return
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		Smoke.fail("%s failed to load" % path)
		return
	if res is Script and not (res as Script).can_instantiate():
		Smoke.fail("%s did not compile" % path)
		return
	if res is PackedScene and not (res as PackedScene).can_instantiate():
		Smoke.fail("%s cannot be instantiated" % path)
		return
	Smoke.ok(path)
